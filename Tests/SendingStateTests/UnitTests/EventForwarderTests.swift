//
//  EventForwarderTests.swift
//  SendingState
//
//  Created by SunSoo Jeon on 23.06.2023.
//

import XCTest
@testable import SendingState

final class EventForwarderTests: XCTestCase {
    var handler: TestActionHandler!

    override func setUp() {
        super.setUp()
        handler = TestActionHandler()
    }

    override func tearDown() {
        handler = nil
        super.tearDown()
    }
}

#if os(iOS) || targetEnvironment(macCatalyst)
import UIKit

@MainActor
extension EventForwarderTests {
    // MARK: - Action Forwarding Without Handler

    func test_events_without_handler_do_not_crash() {
        // Given
        let button = TestFixture.makeButton()

        let forwarder = EventForwarder(button) { _, ctx in
            ctx.control(.touchUpInside) {
                [TestAction.buttonTapped(1)]
            }
        }

        let provider = TestEventForwardableUIView(forwarder: forwarder)
        provider.addSubview(button)

        // When - No handler assigned

        // Then - Should not crash
        XCTAssertNoThrow(
            TestActionTrigger.simulateControl(button, for: .touchUpInside)
        )
    }

    // MARK: - Control Events -> Action Flow

    func test_button_touchUpInside_forwards_action() {
        // Given
        let button = TestFixture.makeButton(tag: 90)

        let forwarder = EventForwarder(button) { sender, ctx in
            ctx.control(.touchUpInside) {
                [TestAction.buttonTapped(sender.tag)]
            }
        }

        let provider = TestEventForwardableUIView(forwarder: forwarder)
        provider.addSubview(button)
        provider.ss.addActionHandler(to: handler)

        // When
        TestActionTrigger.simulateControl(button, for: .touchUpInside)

        // Then
        XCTAssertEqual(handler.handledActions.count, 1)
        XCTAssertEqual(handler.handledActions.first, .buttonTapped(90))
    }

    func test_switch_valueChanged_forwards_action() {
        // Given
        let aSwitch = TestFixture.makeSwitch(isOn: false)

        let forwarder = EventForwarder(aSwitch) { sender, ctx in
            ctx.control(.valueChanged) {
                [TestAction.switchChanged(sender.isOn)]
            }
        }

        let provider = TestEventForwardableUIView(forwarder: forwarder)
        provider.addSubview(aSwitch)
        provider.ss.addActionHandler(to: handler)

        // When
        TestActionTrigger.simulateSwitch(aSwitch, flag: true)

        // Then
        XCTAssertEqual(handler.handledActions.count, 1)
        if case .switchChanged(let value) = handler.handledActions.first {
            XCTAssertTrue(value)
        } else {
            XCTFail("Expected switchChanged action")
        }
    }

    func test_slider_valueChanged_forwards_action() {
        // Given
        let slider = TestFixture.makeSlider(value: 0.0)

        let forwarder = EventForwarder(slider) { sender, ctx in
            ctx.control(.valueChanged) {
                [TestAction.sliderChanged(sender.value)]
            }
        }

        let provider = TestEventForwardableUIView(forwarder: forwarder)
        provider.addSubview(slider)
        provider.ss.addActionHandler(to: handler)

        // When
        TestActionTrigger.simulateSlider(slider, value: 0.37)

        // Then
        XCTAssertEqual(handler.handledActions.count, 1)
        if case .sliderChanged(let value) = handler.handledActions.first {
            XCTAssertEqual(value, 0.37, accuracy: 0.01)
        } else {
            XCTFail("Expected sliderChanged action")
        }
    }

    // MARK: - Multiple Actions per Event

    func test_single_event_forwards_multiple_actions() {
        // Given
        let button = TestFixture.makeButton(tag: 11)

        let forwarder = EventForwarder(button) { sender, ctx in
            ctx.control(.touchUpInside) {
                [
                    TestAction.buttonTapped(sender.tag),
                    TestAction.sendClickLog,
                    TestAction.custom("sendExternalSDKLog")
                ]
            }
        }

        let provider = TestEventForwardableUIView(forwarder: forwarder)
        provider.addSubview(button)
        provider.ss.addActionHandler(to: handler)

        // When
        TestActionTrigger.simulateControl(button, for: .touchUpInside)

        // Then
        XCTAssertEqual(handler.handledActions.count, 3)
        XCTAssertEqual(handler.handledActions[0], .buttonTapped(11))
        XCTAssertEqual(handler.handledActions[1], .sendClickLog)
        XCTAssertEqual(handler.handledActions[2], .custom("sendExternalSDKLog"))
    }

    func test_multiple_events_on_same_control() {
        // Given
        let button = TestFixture.makeButton(tag: 30)

        let forwarder = EventForwarder(button) { sender, ctx in
            ctx.control(.touchUpInside) {
                [TestAction.buttonTapped(sender.tag)]
            }
            ctx.control(.touchDown) {
                [TestAction.custom("touchDown")]
            }
        }

        let provider = TestEventForwardableUIView(forwarder: forwarder)
        provider.addSubview(button)
        provider.ss.addActionHandler(to: handler)

        // When
        TestActionTrigger.simulateControl(button, for: .touchDown)
        TestActionTrigger.simulateControl(button, for: .touchUpInside)

        // Then
        XCTAssertEqual(handler.handledActions.count, 2)
        XCTAssertEqual(handler.handledActions[0], .custom("touchDown"))
        XCTAssertEqual(handler.handledActions[1], .buttonTapped(30))
    }

    // MARK: - Event Filtering

    func test_only_registered_events_forward_actions() {
        // Given
        let button = TestFixture.makeButton()

        let forwarder = EventForwarder(button) { _, ctx in
            ctx.control(.touchUpInside) {
                [TestAction.buttonTapped(11)]
            }
        }

        let provider = TestEventForwardableUIView(forwarder: forwarder)
        provider.addSubview(button)
        provider.ss.addActionHandler(to: handler)

        // When - Send unregistered event
        TestActionTrigger.simulateControl(button, for: .touchDown)

        // Then - No action should be forwarded
        XCTAssertEqual(handler.handledActions.count, 0)

        // When - Send registered event
        TestActionTrigger.simulateControl(button, for: .touchUpInside)

        // Then
        XCTAssertEqual(handler.handledActions.count, 1)
    }

    // MARK: - Repeated Events

    func test_repeated_events_forward_each_time() {
        // Given
        let button = TestFixture.makeButton(tag: 2)

        let forwarder = EventForwarder(button) { sender, ctx in
            ctx.control(.touchUpInside) {
                [TestAction.buttonTapped(sender.tag)]
            }
        }

        let provider = TestEventForwardableUIView(forwarder: forwarder)
        provider.addSubview(button)
        provider.ss.addActionHandler(to: handler)

        // When
        for _ in 0..<5 {
            TestActionTrigger.simulateControl(button, for: .touchUpInside)
        }

        // Then
        XCTAssertEqual(handler.handledActions.count, 5)
        handler.handledActions.forEach { action in
            XCTAssertEqual(action, .buttonTapped(2))
        }
    }

    // MARK: - Different Controls Same Event

    func test_different_controls_same_event_forwards_correctly() {
        // Given
        let button1 = TestFixture.makeButton(tag: 11)
        let button2 = TestFixture.makeButton(tag: 23)

        let group = SenderGroup {
            EventForwarder(button1) { sender, ctx in
                ctx.control(.touchUpInside) {
                    [TestAction.buttonTapped(sender.tag)]
                }
            }
            EventForwarder(button2) { sender, ctx in
                ctx.control(.touchUpInside) {
                    [TestAction.buttonTapped(sender.tag)]
                }
            }
        }

        let provider = TestEventForwardableUIView(forwarder: group)
        provider.addSubview(button1)
        provider.addSubview(button2)
        provider.ss.addActionHandler(to: handler)

        // When
        TestActionTrigger.simulateControl(button1, for: .touchUpInside)
        TestActionTrigger.simulateControl(button2, for: .touchUpInside)

        // Then
        XCTAssertEqual(handler.handledActions.count, 2)
        XCTAssertEqual(handler.handledActions[0], .buttonTapped(11))
        XCTAssertEqual(handler.handledActions[1], .buttonTapped(23))
    }

    // MARK: - Target Wiring Verification

    func test_button_addTarget_wired_with_invoke_selector() {
        // Given
        let button = TestFixture.makeButton()

        // When
        let forwarder = EventForwarder(button) { sender, ctx in
            ctx.control(.touchUpInside) {
                [TestAction.buttonTapped(sender.tag)]
            }
        }
        let provider = TestEventForwardableUIView(forwarder: forwarder)
        provider.addSubview(button)
        provider.ss.addActionHandler(to: handler)

        // Then
        let targets = button.allTargets
        XCTAssertEqual(targets.count, 1)

        let actions = button.actions(forTarget: targets.first, forControlEvent: .touchUpInside)
        XCTAssertNotNil(actions)
        XCTAssertTrue(actions?.contains(where: { $0.contains("invoke") }) == true)
    }
}
#endif
