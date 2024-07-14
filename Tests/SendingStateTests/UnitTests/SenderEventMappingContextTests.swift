//
//  SenderEventMappingContextTests.swift
//  SendingState
//
//  Created by SunSoo Jeon on 23.06.2023.
//

import XCTest
@testable import SendingState

final class SenderEventMappingContextTests: XCTestCase {
    var context: SenderEventMappingContext!

    override func setUp() {
        super.setUp()
        context = SenderEventMappingContext()
    }

    override func tearDown() {
        context = nil
        super.tearDown()
    }
}

#if os(iOS) || targetEnvironment(macCatalyst)
import UIKit

extension SenderEventMappingContextTests {
    // MARK: - Control Events

    func test_control_creates_mapping() {
        // Given
        let mapping = context.control(.touchUpInside) {
            [TestAction.buttonTapped(1)]
        }

        // Then
        XCTAssertEqual(mapping.count, 1)

        let event = SenderEvent.control(.init(.touchUpInside))
        XCTAssertNotNil(mapping[event])
        XCTAssertEqual(mapping[event]?().count, 1)
    }

    func test_control_mapping_contains_correct_actions() {
        // Given
        let actions = [
            TestAction.buttonTapped(90),
            TestAction.sendClickLog
        ]

        // When
        let mapping = context.control(.touchUpInside) { actions }

        let event = SenderEvent.control(.init(.touchUpInside))

        // Then
        XCTAssertEqual(mapping[event]?(), actions)
    }

    // MARK: - Custom Gesture

    func test_gesture_creates_mapping() {
        // Given
        let gestureEvent = SenderEvent.Gesture(
            kind: .tap,
            states: [.recognized]
        )

        // When
        let mapping = context.gesture(gestureEvent) {
            [TestAction.viewTapped]
        }

        // Then
        XCTAssertEqual(mapping.count, 1)

        let event = SenderEvent.gesture(gestureEvent)
        XCTAssertNotNil(mapping[event])
    }

    // MARK: - Tap Gesture

    func test_tap_gesture_default_configuration() {
        // Given
        let mapping = context.tapGesture() {
            [TestAction.viewTapped]
        }

        // Then
        XCTAssertEqual(mapping.count, 1)

        // Verify gesture configuration
        let key = mapping.keys.first
        if case .gesture(let gesture) = key {
            XCTAssertEqual(gesture.kind, .tap)
            XCTAssertEqual(gesture.states, [.recognized])
            XCTAssertEqual(gesture.numberOfTaps, 1)
            XCTAssertEqual(gesture.numberOfTouches, 1)
        } else {
            XCTFail("Expected gesture event")
        }
    }

    func test_tap_gesture_custom_configuration() {
        // Given
        let mapping = context.tapGesture(
            numberOfTaps: 2,
            numberOfTouches: 2,
            on: [.began, .ended]
        ) {
            [TestAction.custom("Double Two Finger Tap")]
        }

        // Then
        let key = mapping.keys.first
        if case .gesture(let gesture) = key {
            XCTAssertEqual(gesture.numberOfTaps, 2)
            XCTAssertEqual(gesture.numberOfTouches, 2)
            XCTAssertEqual(gesture.states, [.began, .ended])
        } else {
            XCTFail("Expected gesture event")
        }
    }

    // MARK: - Long Press Gesture

    func test_long_press_gesture_default() {
        // Given
        let mapping = context.longPressGesture() {
            [TestAction.longPressed]
        }

        // Then
        let key = mapping.keys.first
        if case .gesture(let gesture) = key {
            XCTAssertEqual(gesture.kind, .longPress)
            XCTAssertEqual(gesture.states, [.began, .ended])
            XCTAssertEqual(gesture.minimumPressDuration, 0.5)
        } else {
            XCTFail("Expected gesture event")
        }
    }

    func test_long_press_gesture_custom_duration() {
        // Given
        let mapping = context.longPressGesture(
            minimumPressDuration: 2.0,
            on: [.began]
        ) {
            [TestAction.longPressed]
        }

        // Then
        let key = mapping.keys.first
        if case .gesture(let gesture) = key {
            XCTAssertEqual(gesture.minimumPressDuration, 2.0)
            XCTAssertEqual(gesture.states, [.began])
        } else {
            XCTFail("Expected gesture event")
        }
    }

    // MARK: - Swipe Gesture

    func test_swipe_gesture_default() {
        // Given
        let mapping = context.swipeGesture() {
            [TestAction.custom("Swipe")]
        }

        // Then
        let key = mapping.keys.first
        if case .gesture(let gesture) = key {
            XCTAssertEqual(gesture.kind, .swipe)
            XCTAssertEqual(gesture.direction, .right)
            XCTAssertEqual(gesture.states, [.recognized])
        } else {
            XCTFail("Expected gesture event")
        }
    }

    func test_swipe_gesture_custom_direction() {
        // Given
        let mapping = context.swipeGesture(
            direction: .left,
            numberOfTouches: 2
        ) {
            [TestAction.custom("Left Swipe")]
        }

        // Then
        let key = mapping.keys.first
        if case .gesture(let gesture) = key {
            XCTAssertEqual(gesture.direction, .left)
            XCTAssertEqual(gesture.numberOfTouches, 2)
        } else {
            XCTFail("Expected gesture event")
        }
    }

    // MARK: - Pan Gesture

    func test_pan_gesture() {
        // Given
        let mapping = context.panGesture() {
            [TestAction.viewPanned]
        }

        // Then
        let key = mapping.keys.first
        if case .gesture(let gesture) = key {
            XCTAssertEqual(gesture.kind, .pan)
            XCTAssertEqual(gesture.states, [.changed, .ended])
        } else {
            XCTFail("Expected gesture event")
        }
    }

    func test_pan_gesture_custom_states() {
        // Given
        let mapping = context.panGesture(
            on: [.began, .changed, .ended, .cancelled]
        ) {
            [TestAction.viewPanned]
        }

        // Then
        let key = mapping.keys.first
        if case .gesture(let gesture) = key {
            let expectedStates: Set<UIGestureRecognizer.State> = [
                .began, .changed, .ended, .cancelled
            ]
            XCTAssertEqual(gesture.states, expectedStates)
        } else {
            XCTFail("Expected gesture event")
        }
    }

    // MARK: - Pinch Gesture

    func test_pinch_gesture() {
        // Given
        let mapping = context.pinchGesture() {
            [TestAction.viewPinched]
        }

        // Then
        let key = mapping.keys.first
        if case .gesture(let gesture) = key {
            XCTAssertEqual(gesture.kind, .pinch)
            XCTAssertEqual(gesture.states, [.changed, .ended])
        } else {
            XCTFail("Expected gesture event")
        }
    }

    // MARK: - Rotation Gesture

    func test_rotation_gesture() {
        // Given
        let mapping = context.rotationGesture() {
            [TestAction.custom("Rotate")]
        }

        // Then
        let key = mapping.keys.first
        if case .gesture(let gesture) = key {
            XCTAssertEqual(gesture.kind, .rotation)
        } else {
            XCTFail("Expected gesture event")
        }
    }

    // MARK: - Screen Edge Gesture

    func test_screen_edge_gesture_default() {
        // Given
        let mapping = context.screenEdgeGesture() {
            [TestAction.custom("Edge")]
        }

        // Then
        let key = mapping.keys.first
        if case .gesture(let gesture) = key {
            XCTAssertEqual(gesture.kind, .screenEdge)
            XCTAssertEqual(gesture.edges, .left)
        } else {
            XCTFail("Expected gesture event")
        }
    }

    func test_screen_edge_gesture_custom_edge() {
        // Given
        let mapping = context.screenEdgeGesture(
            edges: .right,
            on: [.began, .ended]
        ) {
            [TestAction.custom("Right Edge")]
        }

        // Then
        let key = mapping.keys.first
        if case .gesture(let gesture) = key {
            XCTAssertEqual(gesture.edges, .right)
            XCTAssertEqual(gesture.states, [.began, .ended])
        } else {
            XCTFail("Expected gesture event")
        }
    }

    // MARK: - Hover Gesture

    @available(iOS 13.4, *)
    func test_hover_gesture() {
        // Given
        let mapping = context.hoverGesture() {
            [TestAction.custom("Hover")]
        }

        // Then
        let key = mapping.keys.first
        if case .gesture(let gesture) = key {
            XCTAssertEqual(gesture.kind, .hover)
            XCTAssertEqual(gesture.states, [.changed])
        } else {
            XCTFail("Expected gesture event")
        }
    }

    // MARK: - Multiple Mappings

    func test_multiple_gesture_mappings() {
        // Given
        // Create multiple mappings using same context
        let tap = context.tapGesture() { [TestAction.viewTapped] }
        let pinch = context.pinchGesture() { [TestAction.viewPinched] }
        let pan = context.panGesture() { [TestAction.viewPanned] }

        // Then
        XCTAssertEqual(tap.count, 1)
        XCTAssertEqual(pinch.count, 1)
        XCTAssertEqual(pan.count, 1)

        // Keys should be different
        XCTAssertNotEqual(tap.keys.first, pinch.keys.first)
        XCTAssertNotEqual(pinch.keys.first, pan.keys.first)
    }
}
#endif

