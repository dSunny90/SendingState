//
//  SenderEventMappingContextTests+State.swift
//  SendingState
//
//  Created by SunSoo Jeon on 23.06.2023.
//

import XCTest
@testable import SendingState

#if os(iOS) || targetEnvironment(macCatalyst)
import UIKit

@MainActor
extension SenderEventMappingContextTests {
    // MARK: - Control State Overload

    func test_control_state_returns_typed_state_at_event_time() {
        // Given
        let button = UIButton()
        button.boundState = TestConfigurableUIView.Model(text: "Sending", value: 20)

        // When
        let ctx = SenderEventMappingContext(sender: button)
        let mapping: [SenderEvent: () -> [TestAction]] = ctx.control(.touchUpInside) {
            (state: TestConfigurableUIView.Model) in
            [.buttonTapped(state.value)]
        }

        let event = SenderEvent.control(.init(.touchUpInside))
        let actions = mapping[event]?() ?? []

        // Then
        XCTAssertEqual(actions.count, 1)
        XCTAssertEqual(actions.first, .buttonTapped(20))
    }

    // MARK: - Gesture State Overload

    func test_gesture_state_resolves_correctly() {
        // Given
        let view = UIView()
        view.boundState = TestConfigurableUIView.Model(text: "State", value: 20)

        // When
        let ctx = SenderEventMappingContext(sender: view)
        let gestureEvent = SenderEvent.Gesture(kind: .tap, states: [.recognized])

        let mapping: [SenderEvent: () -> [TestAction]] = ctx.gesture(gestureEvent) {
            (state: TestConfigurableUIView.Model) in
            [.custom(state.text)]
        }

        let event = SenderEvent.gesture(gestureEvent)
        let actions = mapping[event]?() ?? []

        // Then
        XCTAssertEqual(actions.count, 1)
        XCTAssertEqual(actions.first, .custom("State"))
    }

    // MARK: - Gesture Convenience State Overloads

    func test_tapGesture_state_creates_correct_event_key() {
        // Given
        let view = UIView()
        view.boundState = "String"

        // When
        let ctx = SenderEventMappingContext(sender: view)
        let mapping: [SenderEvent: () -> [TestAction]] = ctx.tapGesture {
            (state: String) in
            [.custom(state)]
        }

        // Then
        let key = mapping.keys.first
        if case .gesture(let gesture) = key {
            XCTAssertEqual(gesture.kind, .tap)
            XCTAssertEqual(gesture.states, [.recognized])
            XCTAssertEqual(gesture.numberOfTaps, 1)
        } else {
            XCTFail("Expected gesture event")
        }

        let actions = mapping.values.first?() ?? []
        XCTAssertEqual(actions.first, .custom("String"))
    }

    func test_longPressGesture_state_overload() {
        // Given
        let view = UIView()
        view.boundState = 11

        // When
        let ctx = SenderEventMappingContext(sender: view)
        let mapping: [SenderEvent: () -> [TestAction]] = ctx.longPressGesture {
            (state: Int) in
            [.buttonTapped(state)]
        }

        // Then
        let key = mapping.keys.first
        if case .gesture(let gesture) = key {
            XCTAssertEqual(gesture.kind, .longPress)
            XCTAssertEqual(gesture.minimumPressDuration, 0.5)
        } else {
            XCTFail("Expected gesture event")
        }

        let actions = mapping.values.first?() ?? []
        XCTAssertEqual(actions.first, .buttonTapped(11))
    }

    func test_swipeGesture_state_overload() {
        // Given
        let view = UIView()
        view.boundState = "SendingState"

        // When
        let ctx = SenderEventMappingContext(sender: view)
        let mapping: [SenderEvent: () -> [TestAction]] = ctx.swipeGesture(direction: .left) {
            (state: String) in
            [.custom(state)]
        }

        // Then
        let key = mapping.keys.first
        if case .gesture(let gesture) = key {
            XCTAssertEqual(gesture.kind, .swipe)
            XCTAssertEqual(gesture.direction, .left)
        } else {
            XCTFail("Expected gesture event")
        }
    }

    func test_panGesture_state_overload() {
        // Given
        let view = UIView()
        view.boundState = "SendingState"

        // When
        let ctx = SenderEventMappingContext(sender: view)
        let mapping: [SenderEvent: () -> [TestAction]] = ctx.panGesture {
            (state: String) in
            [.custom(state)]
        }

        // Then
        let key = mapping.keys.first
        if case .gesture(let gesture) = key {
            XCTAssertEqual(gesture.kind, .pan)
        } else {
            XCTFail("Expected gesture event")
        }
    }

    func test_pinchGesture_state_overload() {
        // Given
        let view = UIView()
        view.boundState = "SendingState"

        // When
        let ctx = SenderEventMappingContext(sender: view)
        let mapping: [SenderEvent: () -> [TestAction]] = ctx.pinchGesture {
            (state: String) in
            [.custom(state)]
        }

        // Then
        let key = mapping.keys.first
        if case .gesture(let gesture) = key {
            XCTAssertEqual(gesture.kind, .pinch)
        } else {
            XCTFail("Expected gesture event")
        }
    }

    func test_rotationGesture_state_overload() {
        // Given
        let view = UIView()
        view.boundState = "SendingState"

        // When
        let ctx = SenderEventMappingContext(sender: view)
        let mapping: [SenderEvent: () -> [TestAction]] = ctx.rotationGesture {
            (state: String) in
            [.custom(state)]
        }

        // Then
        let key = mapping.keys.first
        if case .gesture(let gesture) = key {
            XCTAssertEqual(gesture.kind, .rotation)
        } else {
            XCTFail("Expected gesture event")
        }
    }

    func test_screenEdgeGesture_state_overload() {
        // Given
        let view = UIView()
        view.boundState = "SendingState"

        // When
        let ctx = SenderEventMappingContext(sender: view)
        let mapping: [SenderEvent: () -> [TestAction]] = ctx.screenEdgeGesture(edges: .right) {
            (state: String) in
            [.custom(state)]
        }

        // Then
        let key = mapping.keys.first
        if case .gesture(let gesture) = key {
            XCTAssertEqual(gesture.kind, .screenEdge)
            XCTAssertEqual(gesture.edges, .right)
        } else {
            XCTFail("Expected gesture event")
        }
    }

    @available(iOS 13.4, *)
    func test_hoverGesture_state_overload() {
        // Given
        let view = UIView()
        view.boundState = "SendingState"

        // When
        let ctx = SenderEventMappingContext(sender: view)
        let mapping: [SenderEvent: () -> [TestAction]] = ctx.hoverGesture {
            (state: String) in
            [.custom(state)]
        }

        // Then
        let key = mapping.keys.first
        if case .gesture(let gesture) = key {
            XCTAssertEqual(gesture.kind, .hover)
        } else {
            XCTFail("Expected gesture event")
        }
    }

    // MARK: - Coexistence

    func test_state_and_stateless_overloads_coexist_in_builder() {
        // Given
        let button = UIButton()
        button.boundState = TestConfigurableUIView.Model(text: "Swift", value: 16)

        // When
        let forwarder = EventForwarder(button) { sender, ctx in
            // Stateless overload
            ctx.control(.touchDown) {
                [TestAction.custom("touchDown")]
            }
            // State-aware overload
            ctx.control(.touchUpInside) {
                (state: TestConfigurableUIView.Model) in
                [TestAction.buttonTapped(state.value)]
            }
        }

        let touchDownActions = forwarder.actions(
            for: button,
            event: .control(.init(.touchDown))
        )
        let touchUpActions = forwarder.actions(
            for: button,
            event: .control(.init(.touchUpInside))
        )

        // Then
        XCTAssertEqual(touchDownActions.count, 1)
        XCTAssertEqual(touchDownActions.first as? TestAction, .custom("touchDown"))

        XCTAssertEqual(touchUpActions.count, 1)
        XCTAssertEqual(touchUpActions.first as? TestAction, .buttonTapped(16))
    }

    // MARK: - State Updates Reflected

    func test_state_change_reflected_in_next_invocation() {
        // Given
        let button = UIButton()
        button.boundState = TestConfigurableUIView.Model(text: "Cmd", value: 2)

        // When
        let ctx = SenderEventMappingContext(sender: button)
        let mapping: [SenderEvent: () -> [TestAction]] = ctx.control(.touchUpInside) {
            (state: TestConfigurableUIView.Model) in
            [.buttonTapped(state.value)]
        }

        let event = SenderEvent.control(.init(.touchUpInside))

        // Then
        // First invocation
        let actions1 = mapping[event]?() ?? []
        XCTAssertEqual(actions1.first, .buttonTapped(2))

        // Update state
        button.boundState = TestConfigurableUIView.Model(text: "Ctrl", value: 119)

        // Second invocation — should reflect updated state
        let actions2 = mapping[event]?() ?? []
        XCTAssertEqual(actions2.first, .buttonTapped(119))
    }
}
#endif
