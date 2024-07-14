//
//  EventForwardingPerformanceTests.swift
//  SendingState
//
//  Created by SunSoo Jeon on 26.06.2023.
//

import XCTest
@testable import SendingState

#if os(iOS) || targetEnvironment(macCatalyst)
import UIKit

@MainActor
final class EventForwardingPerformanceTests: XCTestCase {

    var handler: TestActionHandler!

    override func setUp() {
        super.setUp()
        handler = TestActionHandler()
    }

    override func tearDown() {
        handler = nil
        super.tearDown()
    }

    // MARK: - Event Forwarder Creation

    /// Measure EventForwarder creation performance
    func test_event_forwarder_creation_performance() {
        measure {
            for _ in 0..<10000 {
                let button = UIButton()
                _ = EventForwarder(button) { sender, ctx in
                    ctx.control(.touchUpInside) {
                        [TestAction.buttonTapped(sender.tag)]
                    }
                }
            }
        }
    }

    /// Measure SenderGroup creation with multiple forwarders
    func test_sender_group_creation_performance() {
        measure {
            for _ in 0..<1000 {
                let button1 = UIButton()
                let button2 = UIButton()
                let switch1 = UISwitch()
                let slider1 = UISlider()
                let view1 = UIView()

                _ = SenderGroup {
                    EventForwarder(button1) { _, ctx in
                        ctx.control(.touchUpInside) { [TestAction.buttonTapped(1)] }
                    }
                    EventForwarder(button2) { _, ctx in
                        ctx.control(.touchUpInside) { [TestAction.buttonTapped(2)] }
                    }
                    EventForwarder(switch1) { _, ctx in
                        ctx.control(.valueChanged) { [TestAction.switchChanged(true)] }
                    }
                    EventForwarder(slider1) { _, ctx in
                        ctx.control(.valueChanged) { [TestAction.sliderChanged(0.5)] }
                    }
                    EventForwarder(view1) { _, ctx in
                        ctx.tapGesture() { [TestAction.viewTapped] }
                    }
                }
            }
        }
    }

    // MARK: - Action Handler Assignment

    /// Measure handler assignment performance
    func test_handler_assignment_performance() {
        let views = (0..<1000).map { _ in TestEventForwardingUIView() }

        measure {
            for view in views {
                view.ss.addActionHandler(to: handler)
            }
        }
    }

    /// Measure repeated handler replacement
    func test_handler_replacement_performance() {
        let view = TestEventForwardingUIView()
        let handlers = (0..<1000).map { _ in TestActionHandler() }

        measure {
            for handler in handlers {
                view.ss.addActionHandler(to: handler)
            }
        }
    }

    // MARK: - Event Dispatch

    /// Measure control event dispatch performance
    func test_control_event_dispatch_performance() {
        let view = TestEventForwardingUIView()
        view.ss.addActionHandler(to: handler)

        measure {
            for _ in 0..<10000 {
                TestActionTrigger.simulateControl(view.button, for: .touchUpInside)
            }
        }
    }

    /// Measure multiple control types dispatch
    func test_multiple_control_dispatch_performance() {
        let view = TestEventForwardingUIView()
        view.ss.addActionHandler(to: handler)

        measure {
            for _ in 0..<1000 {
                TestActionTrigger.simulateControl(view.button, for: .touchUpInside)
                TestActionTrigger.simulateSwitch(view.testSwitch, flag: !view.testSwitch.isOn)
                TestActionTrigger.simulateSlider(view.slider, value: view.slider.value.advanced(by: 0.001))
            }
        }
    }

    // MARK: - Action Lookup

    /// Measure action lookup performance in SenderGroup
    func test_action_lookup_performance() {
        let buttons = (0..<20).map { _ in UIButton() }

        let group = SenderGroup {
            EventForwarder(buttons[0]) { _, ctx in ctx.control(.touchUpInside) { [TestAction.buttonTapped(0)] } }
            EventForwarder(buttons[1]) { _, ctx in ctx.control(.touchUpInside) { [TestAction.buttonTapped(1)] } }
            EventForwarder(buttons[2]) { _, ctx in ctx.control(.touchUpInside) { [TestAction.buttonTapped(2)] } }
            EventForwarder(buttons[3]) { _, ctx in ctx.control(.touchUpInside) { [TestAction.buttonTapped(3)] } }
            EventForwarder(buttons[4]) { _, ctx in ctx.control(.touchUpInside) { [TestAction.buttonTapped(4)] } }
            EventForwarder(buttons[5]) { _, ctx in ctx.control(.touchUpInside) { [TestAction.buttonTapped(5)] } }
            EventForwarder(buttons[6]) { _, ctx in ctx.control(.touchUpInside) { [TestAction.buttonTapped(6)] } }
            EventForwarder(buttons[7]) { _, ctx in ctx.control(.touchUpInside) { [TestAction.buttonTapped(7)] } }
            EventForwarder(buttons[8]) { _, ctx in ctx.control(.touchUpInside) { [TestAction.buttonTapped(8)] } }
            EventForwarder(buttons[9]) { _, ctx in ctx.control(.touchUpInside) { [TestAction.buttonTapped(9)] } }
        }

        let event = SenderEvent.control(.init(.touchUpInside))

        measure {
            for _ in 0..<1000 {
                for button in buttons.prefix(10) {
                    _ = group.actions(for: button, event: event)
                }
            }
        }
    }

    // MARK: - Type Erasure

    /// Measure AnyEventForwarder overhead
    func test_any_event_forwarder_overhead() {
        let button = UIButton()

        measure {
            for _ in 0..<10000 {
                let forwarder = EventForwarder(button) { sender, ctx in
                    ctx.control(.touchUpInside) {
                        [TestAction.buttonTapped(sender.tag)]
                    }
                }
                let anyForwarder = AnyEventForwarder(forwarder)
                _ = anyForwarder.allMappings
            }
        }
    }

    // MARK: - Gesture Setup

    /// Measure gesture recognizer setup performance
    func test_gesture_setup_performance() {
        measure {
            for _ in 0..<1000 {
                let view = UIView()
                _ = EventForwarder(view) { _, ctx in
                    ctx.tapGesture() { [TestAction.viewTapped] }
                    ctx.pinchGesture() { [TestAction.viewPinched] }
                    ctx.panGesture() { [TestAction.viewPanned] }
                    ctx.longPressGesture() { [TestAction.longPressed] }
                }
            }
        }
    }

    // MARK: - Large Scale

    /// Measure performance with many controls
    func test_large_scale_control_management() {
        var buttons: [UIButton] = []
        var forwarders: [EventForwardable] = []

        for i in 0..<1000 {
            let button = UIButton()
            button.tag = i
            buttons.append(button)

            let forwarder = EventForwarder(button) { sender, ctx in
                ctx.control(.touchUpInside) {
                    [TestAction.buttonTapped(sender.tag)]
                }
            }
            forwarders.append(forwarder)
        }

        measure {
            // Simulate setup and teardown
            for (button, forwarder) in zip(buttons, forwarders) {
                _ = forwarder.actions(
                    for: button,
                    event: .control(.init(.touchUpInside))
                )
            }
        }
    }

    // MARK: - Memory

    /// Measure memory usage for event forwarding setup
    func test_event_forwarding_memory_usage() {
        var views: [TestEventForwardingUIView] = []

        measure(metrics: [XCTMemoryMetric()]) {
            views.removeAll()
            for _ in 0..<1000 {
                let view = TestEventForwardingUIView()
                view.ss.addActionHandler(to: handler)
                views.append(view)
            }
        }
    }

    // MARK: - Mapping Context

    /// Measure SenderEventMappingContext performance
    func test_mapping_context_performance() {
        measure {
            for _ in 0..<10000 {
                let ctx = SenderEventMappingContext()
                _ = ctx.control(.touchUpInside) { [TestAction.buttonTapped(1)] }
                _ = ctx.control(.valueChanged) { [TestAction.switchChanged(true)] }
                _ = ctx.tapGesture() { [TestAction.viewTapped] }
                _ = ctx.longPressGesture() { [TestAction.longPressed] }
            }
        }
    }
}
#endif
