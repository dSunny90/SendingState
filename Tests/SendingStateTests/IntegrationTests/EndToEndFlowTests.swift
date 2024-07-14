//
//  EndToEndFlowTests.swift
//  SendingState
//
//  Created by SunSoo Jeon on 26.06.2023.
//

import XCTest
@testable import SendingState

#if os(iOS) || targetEnvironment(macCatalyst)
import UIKit

@MainActor
final class EndToEndFlowTests: XCTestCase {
    var handler: TestActionHandler!

    override func setUp() {
        super.setUp()
        handler = TestActionHandler()
    }

    override func tearDown() {
        handler = nil
        super.tearDown()
    }

    // MARK: - Single Control Flow

    func test_button_tap_complete_flow() {
        // Given
        let view = TestEventForwardingUIView()
        view.ss.addActionHandler(to: handler)
        view.button.tag = 90

        // When
        TestActionTrigger.simulateControl(view.button, for: .touchUpInside)

        // Then
        XCTAssertEqual(handler.handledActions.count, 1)
        XCTAssertEqual(handler.handledActions.first, .buttonTapped(90))
    }

    func test_switch_change_complete_flow() {
        // Given
        let view = TestEventForwardingUIView()
        view.ss.addActionHandler(to: handler)
        TestActionTrigger.simulateSwitch(view.testSwitch, flag: false)

        // When
        TestActionTrigger.simulateSwitch(view.testSwitch, flag: true)

        // Then
        XCTAssertEqual(handler.handledActions.count, 1)
        if case .switchChanged(let value) = handler.handledActions.first {
            XCTAssertTrue(value)
        } else {
            XCTFail("Expected switchChanged action")
        }
    }

    func test_slider_change_complete_flow() {
        // Given
        let view = TestEventForwardingUIView()
        view.ss.addActionHandler(to: handler)
        TestActionTrigger.simulateSlider(view.slider, value: 0.0)

        // When
        TestActionTrigger.simulateSlider(view.slider, value: 0.74)

        // Then
        XCTAssertEqual(handler.handledActions.count, 1)
        if case .sliderChanged(let value) = handler.handledActions.first {
            XCTAssertEqual(value, 0.74, accuracy: 0.01)
        } else {
            XCTFail("Expected sliderChanged action")
        }
    }

    // MARK: - Multiple Controls Flow

    func test_multiple_controls_sequential() {
        // Given
        let view = TestEventForwardingUIView()
        view.ss.addActionHandler(to: handler)
        view.button.tag = 11

        // When
        TestActionTrigger.simulateControl(view.button, for: .touchUpInside)
        TestActionTrigger.simulateSwitch(view.testSwitch, flag: true)
        TestActionTrigger.simulateSlider(view.slider, value: 0.37)

        // Then
        XCTAssertEqual(handler.handledActions.count, 3)
        XCTAssertTrue(handler.handledActions[0].isButtonTap)
        XCTAssertTrue(handler.handledActions[1].isSwitchChange)
        XCTAssertTrue(handler.handledActions[2].isSliderChange)
    }

    func test_same_control_multiple_times() {
        // Given
        let view = TestEventForwardingUIView()
        view.ss.addActionHandler(to: handler)
        view.button.tag = 30

        // When
        TestActionTrigger.simulateControl(view.button, for: .touchUpInside)
        TestActionTrigger.simulateControl(view.button, for: .touchUpInside)
        TestActionTrigger.simulateControl(view.button, for: .touchUpInside)

        // Then
        XCTAssertEqual(handler.handledActions.count, 3)
        handler.handledActions.forEach { action in
            XCTAssertEqual(action, .buttonTapped(30))
        }
    }

    // MARK: - Gesture Flow

    func test_tap_gesture_complete_flow() {
        // Given
        let view = TestGestureUIView()
        view.ss.addActionHandler(to: handler)

        guard let tapGesture = view.view.gestureRecognizers?
            .first(where: { $0 is UITapGestureRecognizer }) else {
            XCTFail("Tap gesture not found")
            return
        }

        // When - Simulate gesture using helper
        TestActionTrigger.simulateGestureRecognition(tapGesture)

        // Then
        waitUntil(timeout: 1.0) {
            self.handler.handledActions.count > 0
        }

        XCTAssertTrue(handler.handledActions.contains(.viewTapped))
    }

    func test_multiple_gestures_on_same_view() {
        // Given
        let view = TestGestureUIView()
        view.ss.addActionHandler(to: handler)

        let gestures = view.view.gestureRecognizers ?? []
        XCTAssertGreaterThan(gestures.count, 1)

        // Then - Multiple gestures should be attached
        let hasTap = gestures.contains { $0 is UITapGestureRecognizer }
        let hasPinch = gestures.contains { $0 is UIPinchGestureRecognizer }
        let hasPan = gestures.contains { $0 is UIPanGestureRecognizer }
        let hasLongPress = gestures.contains { $0 is UILongPressGestureRecognizer }

        XCTAssertTrue(hasTap)
        XCTAssertTrue(hasPinch)
        XCTAssertTrue(hasPan)
        XCTAssertTrue(hasLongPress)
    }

    func test_multiple_gesture_triggers() {
        // Given
        let view = TestGestureUIView()
        view.ss.addActionHandler(to: handler)

        let gestures = view.view.gestureRecognizers ?? []

        // When - Trigger tap
        if let tap = gestures.first(where: { $0 is UITapGestureRecognizer }) {
            TestActionTrigger.simulateGestureRecognition(tap)
        }

        waitUntil(timeout: 0.5) { self.handler.handledActions.count >= 1 }

        // When - Trigger pinch
        if let pinch = gestures.first(where: { $0 is UIPinchGestureRecognizer }) {
            TestActionTrigger.simulateGestureRecognition(pinch)
        }

        waitUntil(timeout: 0.5) { self.handler.handledActions.count >= 2 }

        // Then
        XCTAssertTrue(handler.handledActions.contains(.viewTapped))
        XCTAssertTrue(handler.handledActions.contains(.viewPinched))
    }

    // MARK: - Configurable + EventForwarding Flow

    func test_configure_then_forward_events() {
        // Given
        let configurableView = TestConfigurableUIView()
        let model = TestConfigurableUIView.Model(text: "Test", value: 90)

        // When - Configure
        configurableView.ss.configure(model)

        // Then
        XCTAssertEqual(configurableView.configureCallCount, 1)
        XCTAssertEqual(configurableView.lastModel, model)
    }

    func test_boundable_binding_flow() {
        // Given
        let view = TestConfigurableUIView()
        let boundable = TestBoundableViewModel(
            contentData: TestConfigurableUIView.Model(text: "Apply", value: 69)
        )

        // When - Bind
        boundable.apply(to: view)

        // Then
        XCTAssertEqual(view.configureCallCount, 1)
        XCTAssertEqual(view.lastModel?.text, "Apply")
        XCTAssertEqual(view.lastModel?.value, 69)
    }

    // MARK: - Handler Replacement Flow

    func test_handler_replacement() {
        // Given
        let view = TestEventForwardingUIView()
        let handler1 = TestActionHandler()
        let handler2 = TestActionHandler()

        // When - Assign first handler and simulate
        view.ss.assignActionHandler(to: handler1)
        TestActionTrigger.simulateControl(view.button, for: .touchUpInside)

        // Then
        XCTAssertEqual(handler1.handledActions.count, 1)
        XCTAssertEqual(handler2.handledActions.count, 0)

        // When - Replace with second handler and simulate
        view.ss.assignActionHandler(to: handler2)
        TestActionTrigger.simulateControl(view.button, for: .touchUpInside)

        // Then - Second handler should receive new actions
        XCTAssertEqual(handler1.handledActions.count, 1) // No new actions
        XCTAssertEqual(handler2.handledActions.count, 1) // New action
    }

    // MARK: - Complex Real-World Scenario

    func test_form_submission_flow() {
        // Given - Simulate a form with multiple inputs
        @MainActor
        class FormView: UIView, EventForwardingProvider {
            let nameField = UITextField()
            let emailField = UITextField()
            let agreeSwitch = UISwitch()
            let submitButton = UIButton()

            var eventForwarder: EventForwardable {
                SenderGroup {
                    EventForwarder(nameField) { _, ctx in
                        ctx.control(.editingChanged) {
                            [TestAction.custom("nameChanged")]
                        }
                    }
                    EventForwarder(emailField) { _, ctx in
                        ctx.control(.editingChanged) {
                            [TestAction.custom("emailChanged")]
                        }
                    }
                    EventForwarder(agreeSwitch) { sender, ctx in
                        ctx.control(.valueChanged) {
                            [TestAction.switchChanged(sender.isOn)]
                        }
                    }
                    EventForwarder(submitButton) { _, ctx in
                        ctx.control(.touchUpInside) {
                            [TestAction.custom("submit")]
                        }
                    }
                }
            }
        }

        let form = FormView()
        form.ss.addActionHandler(to: handler)

        // When - Fill form
        TestActionTrigger.simulateTextField(form.nameField, text: "John")
        TestActionTrigger.simulateTextField(form.emailField, text: "smithjohn@example.com")
        TestActionTrigger.simulateSwitch(form.agreeSwitch, flag: true)
        TestActionTrigger.simulateControl(form.submitButton, for: .touchUpInside)

        // Then
        XCTAssertEqual(handler.handledActions.count, 4)
        XCTAssertEqual(handler.handledActions[0], .custom("nameChanged"))
        XCTAssertEqual(handler.handledActions[1], .custom("emailChanged"))
        XCTAssertEqual(handler.handledActions[2], .switchChanged(true))
        XCTAssertEqual(handler.handledActions[3], .custom("submit"))
    }

    func test_list_cell_interaction_flow() {
        // Given - Simulate table view cell pattern
        class ProductListCell: UITableViewCell, EventForwardingProvider {
            let cartButton = UIButton()
            let clipButton = UIButton()

            var eventForwarder: EventForwardable {
                SenderGroup {
                    EventForwarder(cartButton) { sender, ctx in
                        ctx.control(.touchUpInside) {
                            [TestAction.buttonTapped(sender.tag)]
                        }
                    }
                    EventForwarder(clipButton) { sender, ctx in
                        ctx.control(.touchUpInside) {
                            [TestAction.custom("i_\(sender.tag)")]
                        }
                    }
                }
            }

            override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
                super.init(style: style, reuseIdentifier: reuseIdentifier)
                contentView.addSubview(cartButton)
                contentView.addSubview(clipButton)
            }

            required init?(coder: NSCoder) {
                fatalError("init(coder:) has not been implemented")
            }
        }

        let cell = ProductListCell(style: .default, reuseIdentifier: "Cell")
        cell.ss.addActionHandler(to: handler)
        cell.cartButton.tag = 100
        cell.clipButton.tag = 100

        // When
        TestActionTrigger.simulateControl(cell.cartButton, for: .touchUpInside)
        TestActionTrigger.simulateControl(cell.clipButton, for: .touchUpInside)

        // Then
        XCTAssertEqual(handler.handledActions.count, 2)
        XCTAssertEqual(handler.handledActions[0], .buttonTapped(100))
        XCTAssertEqual(handler.handledActions[1], .custom("i_100"))
    }

    // MARK: - State-Aware EventForwarder Flow

    func test_state_aware_eventForwarder_resolves_state_on_button_tap() {
        // Given
        let cell = StateAwareTestCell()
        cell.ss.addActionHandler(to: handler)

        let model = TestConfigurableUIView.Model(text: "item", value: 77)
        cell.ss.configure(model)

        // When
        TestActionTrigger.simulateControl(cell.button, for: .touchUpInside)

        // Then
        XCTAssertEqual(handler.handledActions.count, 1)
        XCTAssertEqual(handler.handledActions.first, .buttonTapped(77))
    }

    func test_state_aware_eventForwarder_reflects_latest_state() {
        // Given
        let cell = StateAwareTestCell()
        cell.ss.addActionHandler(to: handler)

        // When - Configure with first model and trigger
        cell.ss.configure(TestConfigurableUIView.Model(text: "A", value: 1))
        TestActionTrigger.simulateControl(cell.button, for: .touchUpInside)

        // Then
        XCTAssertEqual(handler.handledActions.last, .buttonTapped(1))

        // When - Reconfigure with second model and trigger
        cell.ss.configure(TestConfigurableUIView.Model(text: "B", value: 99))
        TestActionTrigger.simulateControl(cell.button, for: .touchUpInside)

        // Then — should reflect latest state
        XCTAssertEqual(handler.handledActions.count, 2)
        XCTAssertEqual(handler.handledActions.last, .buttonTapped(99))
    }

    func test_state_aware_with_multiple_senders() {
        // Given
        let cell = StateAwareMultiSenderTestCell()
        cell.ss.addActionHandler(to: handler)
        cell.ss.configure(TestConfigurableUIView.Model(text: "Jeon", value: 59))

        // When
        TestActionTrigger.simulateControl(cell.button1, for: .touchUpInside)
        TestActionTrigger.simulateControl(cell.button2, for: .touchUpInside)

        // Then — both resolve the same state
        XCTAssertEqual(handler.handledActions.count, 2)
        XCTAssertEqual(handler.handledActions[0], .buttonTapped(59))
        XCTAssertEqual(handler.handledActions[1], .custom("Jeon"))
    }
}

// MARK: - Test Helpers for State-Aware Tests

@MainActor
private final class StateAwareTestCell: UIView, Configurable, EventForwardingProvider {
    let button = UIButton()

    var configurer: (StateAwareTestCell, TestConfigurableUIView.Model) -> Void {
        { cell, model in
            cell.button.setTitle(model.text, for: .normal)
        }
    }

    var eventForwarder: EventForwardable {
        EventForwarder(button) { _, ctx in
            ctx.control(.touchUpInside) {
                (state: TestConfigurableUIView.Model) in
                [TestAction.buttonTapped(state.value)]
            }
        }
    }

    override init(frame: CGRect) {
        super.init(frame: .zero)
        addSubview(button)
    }

    required init?(coder: NSCoder) {
        fatalError()
    }
}

@MainActor
private final class StateAwareMultiSenderTestCell: UIView, Configurable, EventForwardingProvider {
    let button1 = UIButton()
    let button2 = UIButton()

    var configurer: (StateAwareMultiSenderTestCell, TestConfigurableUIView.Model) -> Void {
        { _, _ in }
    }

    var eventForwarder: EventForwardable {
        SenderGroup {
            EventForwarder(button1) { _, ctx in
                ctx.control(.touchUpInside) {
                    (state: TestConfigurableUIView.Model) in
                    [TestAction.buttonTapped(state.value)]
                }
            }
            EventForwarder(button2) { _, ctx in
                ctx.control(.touchUpInside) {
                    (state: TestConfigurableUIView.Model) in
                    [TestAction.custom(state.text)]
                }
            }
        }
    }

    override init(frame: CGRect) {
        super.init(frame: .zero)
        addSubview(button1)
        addSubview(button2)
    }

    required init?(coder: NSCoder) {
        fatalError()
    }
}
#endif
