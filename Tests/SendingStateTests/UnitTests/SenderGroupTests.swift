//
//  SenderGroupTests.swift
//  SendingState
//
//  Created by SunSoo Jeon on 23.06.2023.
//

import XCTest
@testable import SendingState

@MainActor
final class SenderGroupTests: XCTestCase {
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

extension SenderGroupTests {
    // MARK: - Basic Grouping

    func test_sender_group_combines_multiple_forwarders() {
        // Given
        let aButton = TestFixture.makeButton(tag: 11)
        let aSwitch = TestFixture.makeSwitch()
        let aSlider = TestFixture.makeSlider()

        //  When
        let group = SenderGroup {
            EventForwarder(aButton) { sender, ctx in
                ctx.control(.touchUpInside) {
                    [TestAction.buttonTapped(sender.tag)]
                }
            }
            EventForwarder(aSwitch) { sender, ctx in
                ctx.control(.valueChanged) {
                    [TestAction.switchChanged(sender.isOn)]
                }
            }
            EventForwarder(aSlider) { sender, ctx in
                ctx.control(.valueChanged) {
                    [TestAction.sliderChanged(sender.value)]
                }
            }
        }

        // Then
        let allMappings = group.allMappings
        XCTAssertEqual(allMappings.count, 3)
    }

    func test_sender_group_forwards_actions_from_all_senders() {
        // Given
        let aButton = TestFixture.makeButton(tag: 90)
        let aSwitch = TestFixture.makeSwitch()

        let group = SenderGroup {
            EventForwarder(aButton) { sender, ctx in
                ctx.control(.touchUpInside) {
                    [TestAction.buttonTapped(sender.tag)]
                }
            }
            EventForwarder(aSwitch) { sender, ctx in
                ctx.control(.valueChanged) {
                    [TestAction.switchChanged(sender.isOn)]
                }
            }
        }

        let provider = TestEventForwardableUIView(forwarder: group)
        provider.addSubview(aButton)
        provider.addSubview(aSwitch)
        provider.ss.addActionHandler(to: handler)

        // When
        TestActionTrigger.simulateControl(aButton, for: .touchUpInside)
        TestActionTrigger.simulateSwitch(aSwitch, flag: true)

        // Then
        XCTAssertEqual(handler.handledActions.count, 2)
        XCTAssertEqual(handler.handledActions[0], .buttonTapped(90))
        XCTAssertEqual(handler.handledActions[1], .switchChanged(true))
    }

    // MARK: - Nested Groups

    func test_sender_group_can_contain_other_groups() {
        // Given
        let button1 = TestFixture.makeButton(tag: 41)
        let button2 = TestFixture.makeButton(tag: 17)
        let aSwitch = TestFixture.makeSwitch()

        let buttonGroup = SenderGroup {
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

        // When
        let switchGroup = SenderGroup {
            EventForwarder(aSwitch) { sender, ctx in
                ctx.control(.valueChanged) {
                    [TestAction.switchChanged(sender.isOn)]
                }
            }
        }

        let masterGroup = SenderGroup {
            buttonGroup
            switchGroup
        }

        // Then
        let allMappings = masterGroup.allMappings
        XCTAssertEqual(allMappings.count, 3)
    }

    // MARK: - Same Sender Multiple Events

    func test_sender_group_handles_multiple_events_on_same_sender() {
        // Given
        let button = TestFixture.makeButton(tag: 100)

        let group = SenderGroup {
            EventForwarder(button) { sender, ctx in
                ctx.control(.touchUpInside) {
                    [TestAction.buttonTapped(sender.tag)]
                }
                ctx.control(.touchDown) {
                    [TestAction.custom("touchDown")]
                }
                ctx.control(.touchUpOutside) {
                    [TestAction.custom("touchUpOutside")]
                }
            }
        }

        let provider = TestEventForwardableUIView(forwarder: group)
        provider.addSubview(button)
        provider.ss.addActionHandler(to: handler)

        // When
        TestActionTrigger.simulateControl(button, for: .touchDown)
        TestActionTrigger.simulateControl(button, for: .touchUpInside)
        TestActionTrigger.simulateControl(button, for: .touchUpOutside)

        // Then
        XCTAssertEqual(handler.handledActions.count, 3)
        XCTAssertEqual(handler.handledActions[0], .custom("touchDown"))
        XCTAssertEqual(handler.handledActions[1], .buttonTapped(100))
        XCTAssertEqual(handler.handledActions[2], .custom("touchUpOutside"))
    }

    // MARK: - Mixed Controls and Gestures

    func test_sender_group_handles_controls_and_gestures_together() {
        // Given
        let button = TestFixture.makeButton(tag: 59)
        let view = TestFixture.makeView()

        let group = SenderGroup {
            EventForwarder(button) { sender, ctx in
                ctx.control(.touchUpInside) {
                    [TestAction.buttonTapped(sender.tag)]
                }
            }
            EventForwarder(view) { _, ctx in
                ctx.tapGesture() {
                    [TestAction.viewTapped]
                }
                ctx.pinchGesture() {
                    [TestAction.viewPinched]
                }
            }
        }

        let provider = TestEventForwardableUIView(forwarder: group)
        provider.addSubview(button)
        provider.addSubview(view)
        provider.ss.addActionHandler(to: handler)

        // When - Button
        TestActionTrigger.simulateControl(button, for: .touchUpInside)

        // Then
        XCTAssertEqual(handler.handledActions.count, 1)
        XCTAssertEqual(handler.handledActions[0], .buttonTapped(59))

        // Then - Verify gestures are attached
        XCTAssertNotNil(view.gestureRecognizers)
        XCTAssertEqual(view.gestureRecognizers?.count, 2)
    }

    // MARK: - Empty Groups

    func test_empty_sender_group_does_not_crash() {
        // Given
        let group = SenderGroup {
            // Empty
        }

        // Then
        XCTAssertEqual(group.allMappings.count, 0)

        // Then - Should not crash when querying
        let actions = group.actions(
            for: UIButton(),
            event: .control(.init(.touchUpInside))
        )
        XCTAssertEqual(actions.count, 0)
    }

    // MARK: - Large Groups

    func test_sender_group_handles_many_senders() {
        // Given
        var buttons: [UIButton] = []
        var forwarders: [EventForwardable] = []

        for i in 0..<20 {
            let button = TestFixture.makeButton(tag: i)
            buttons.append(button)

            let forwarder = EventForwarder(button) { sender, ctx in
                ctx.control(.touchUpInside) {
                    [TestAction.buttonTapped(sender.tag)]
                }
            }
            forwarders.append(forwarder)
        }

        // Can't use result builder with dynamic count, so use AnyEventForwarder
        let group = SenderGroup {
            forwarders[0]
            forwarders[1]
            forwarders[2]
            forwarders[3]
            forwarders[4]
            forwarders[5]
            forwarders[6]
            forwarders[7]
            forwarders[8]
            forwarders[9]
        }

        // Then
        XCTAssertEqual(group.allMappings.count, 10)
    }

    // MARK: - Action Retrieval

    func test_sender_group_actions_returns_correct_actions_for_sender() {
        // Given
        let button1 = TestFixture.makeButton(tag: 59)
        let button2 = TestFixture.makeButton(tag: 63)

        let group = SenderGroup {
            EventForwarder(button1) { sender, ctx in
                ctx.control(.touchUpInside) {
                    [TestAction.buttonTapped(sender.tag)]
                }
            }
            EventForwarder(button2) { sender, ctx in
                ctx.control(.touchUpInside) {
                    [TestAction.custom("Mom")]
                }
            }
        }

        // When
        let actions1 = group.actions(
            for: button1,
            event: .control(.init(.touchUpInside))
        )
        let actions2 = group.actions(
            for: button2,
            event: .control(.init(.touchUpInside))
        )

        // Then
        XCTAssertEqual(actions1.count, 1)
        XCTAssertEqual(actions2.count, 1)
    }

    func test_sender_group_returns_empty_for_unknown_sender() {
        // Given
        let button = TestFixture.makeButton()
        let unknownButton = TestFixture.makeButton()

        let group = SenderGroup {
            EventForwarder(button) { _, ctx in
                ctx.control(.touchUpInside) {
                    [TestAction.buttonTapped(44)]
                }
            }
        }

        // When
        let actions = group.actions(
            for: unknownButton,
            event: .control(.init(.touchUpInside))
        )

        // Then
        XCTAssertEqual(actions.count, 0)
    }

    // MARK: - All Mappings

    func test_all_mappings_includes_all_senders() {
        // Given
        let aButton = TestFixture.makeButton()
        let aSwitch = TestFixture.makeSwitch()
        let aSlider = TestFixture.makeSlider()

        // When
        let group = SenderGroup {
            EventForwarder(aButton) { _, ctx in
                ctx.control(.touchUpInside) { [TestAction.buttonTapped(19)] }
            }
            EventForwarder(aSwitch) { _, ctx in
                ctx.control(.valueChanged) { [TestAction.switchChanged(true)] }
            }
            EventForwarder(aSlider) { _, ctx in
                ctx.control(.valueChanged) { [TestAction.sliderChanged(0.69)] }
            }
        }

        // Then
        let mappings = group.allMappings
        XCTAssertEqual(mappings.count, 3)

        let senders = mappings.map { $0.sender }
        XCTAssertTrue(senders.contains { $0 === aButton })
        XCTAssertTrue(senders.contains { $0 === aSwitch })
        XCTAssertTrue(senders.contains { $0 === aSlider })
    }

    // MARK: - Target Wiring Verification

    func test_sender_group_all_targets_wired() {
        // Given
        let aButton = TestFixture.makeButton()
        let aSwitch = TestFixture.makeSwitch()
        let aSlider = TestFixture.makeSlider()
        let aView = TestFixture.makeView()

        // When
        let group = SenderGroup {
            EventForwarder(aButton) { sender, ctx in
                ctx.control(.touchUpInside) {
                    [TestAction.buttonTapped(sender.tag)]
                }
            }
            EventForwarder(aSwitch) { sender, ctx in
                ctx.control(.valueChanged) {
                    [TestAction.switchChanged(sender.isOn)]
                }
            }
            EventForwarder(aSlider) { sender, ctx in
                ctx.control(.valueChanged) {
                    [TestAction.sliderChanged(sender.value)]
                }
            }
            EventForwarder(aView) { _, ctx in
                ctx.tapGesture() {
                    [TestAction.viewTapped]
                }
            }
        }

        let provider = TestEventForwardableUIView(forwarder: group)
        provider.addSubview(aButton)
        provider.addSubview(aSwitch)
        provider.addSubview(aSlider)
        provider.addSubview(aView)
        provider.ss.addActionHandler(to: handler)

        // Then - Verify control targets
        XCTAssertEqual(aButton.allTargets.count, 1)
        XCTAssertTrue(aButton.actions(forTarget: aButton.allTargets.first, forControlEvent: .touchUpInside)?
            .contains(where: { $0.contains("invoke") }) == true)

        XCTAssertTrue(aSwitch.allTargets.count > 0)
        XCTAssertTrue(aSlider.allTargets.count > 0)

        // Then - Verify gesture
        let tapGesture = aView.gestureRecognizers?.first { $0 is UITapGestureRecognizer }
        XCTAssertNotNil(tapGesture)
    }
}
#endif
