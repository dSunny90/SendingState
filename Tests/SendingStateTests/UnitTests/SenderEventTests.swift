//
//  SenderEventTests.swift
//  SendingState
//
//  Created by SunSoo Jeon on 23.06.2023.
//

import XCTest
@testable import SendingState

final class SenderEventTests: XCTestCase {}

#if os(iOS) || targetEnvironment(macCatalyst)
import UIKit

extension SenderEventTests {
    // MARK: - Control Event Tests

    func test_control_event_wraps_uicontrol_event() {
        // Given
        let event = UIControl.Event.touchUpInside

        // When
        let control = SenderEvent.Control(event)

        // Then
        XCTAssertEqual(control.value, event)
    }

    func test_control_event_hashable() {
        // Given
        let event1 = SenderEvent.Control(.touchUpInside)
        let event2 = SenderEvent.Control(.touchUpInside)
        let event3 = SenderEvent.Control(.valueChanged)

        XCTAssertEqual(event1, event2)
        XCTAssertNotEqual(event1, event3)

        // When
        let set: Set<SenderEvent.Control> = [event1, event2, event3]

        // Then
        XCTAssertEqual(set.count, 2)
    }

    func test_control_event_as_dictionary_key() {
        // Given
        let event = SenderEvent.Control(.touchUpInside)
        var dict: [SenderEvent.Control: String] = [:]

        // When
        dict[event] = "Action"

        // Then
        XCTAssertEqual(dict[event], "Action")
    }

    // MARK: - Gesture Event Tests

    func test_gesture_event_initialization() {
        // Given
        let gesture = SenderEvent.Gesture(
            kind: .tap,
            states: [.recognized],
            numberOfTaps: 1,
            numberOfTouches: 1
        )

        // Then
        XCTAssertEqual(gesture.kind, .tap)
        XCTAssertEqual(gesture.states, [.recognized])
        XCTAssertEqual(gesture.numberOfTaps, 1)
        XCTAssertEqual(gesture.numberOfTouches, 1)
    }

    func test_gesture_event_equality() {
        // Given
        let gesture1 = SenderEvent.Gesture(
            kind: .tap,
            states: [.recognized],
            numberOfTaps: 2
        )

        let gesture2 = SenderEvent.Gesture(
            kind: .tap,
            states: [.recognized],
            numberOfTaps: 2
        )

        let gesture3 = SenderEvent.Gesture(
            kind: .tap,
            states: [.recognized],
            numberOfTaps: 1
        )

        // Then
        XCTAssertEqual(gesture1, gesture2)
        XCTAssertNotEqual(gesture1, gesture3)
    }

    func test_gesture_event_hashable() {
        // Given
        let gesture1 = SenderEvent.Gesture(
            kind: .tap,
            states: [.recognized]
        )

        let gesture2 = SenderEvent.Gesture(
            kind: .pan,
            states: [.changed, .ended]
        )

        // When
        let set: Set<SenderEvent.Gesture> = [gesture1, gesture2]

        // Then
        XCTAssertEqual(set.count, 2)
    }

    // MARK: - Gesture Kind Tests

    func test_gesture_kind_option_set() {
        // Given
        let single: SenderEvent.Gesture.Kind = .tap
        let multiple: SenderEvent.Gesture.Kind = [.tap, .longPress, .swipe]

        // Then
        XCTAssertTrue(multiple.contains(.tap))
        XCTAssertTrue(multiple.contains(.longPress))
        XCTAssertTrue(multiple.contains(.swipe))
        XCTAssertFalse(multiple.contains(.pan))

        XCTAssertFalse(single.contains(.longPress))
    }

    func test_gesture_kind_all_types() {
        // Then
        // Common
        XCTAssertNotNil(SenderEvent.Gesture.Kind.tap)
        XCTAssertNotNil(SenderEvent.Gesture.Kind.longPress)
        XCTAssertNotNil(SenderEvent.Gesture.Kind.swipe)

        // Continuous
        XCTAssertNotNil(SenderEvent.Gesture.Kind.pan)
        XCTAssertNotNil(SenderEvent.Gesture.Kind.pinch)
        XCTAssertNotNil(SenderEvent.Gesture.Kind.rotation)

        // Edge
        XCTAssertNotNil(SenderEvent.Gesture.Kind.screenEdge)

        // Hover (iOS 13.0+)
        if #available(iOS 13.0, *) {
            XCTAssertNotNil(SenderEvent.Gesture.Kind.hover)
        }
    }

    func test_gesture_kind_combination() {
        // Given
        let basic: SenderEvent.Gesture.Kind = [.tap, .longPress]
        let continuous: SenderEvent.Gesture.Kind = [.pan, .pinch, .rotation]

        // When
        let all: SenderEvent.Gesture.Kind = basic.union(continuous)

        // Then
        XCTAssertTrue(all.contains(.tap))
        XCTAssertTrue(all.contains(.pan))
        XCTAssertTrue(all.contains(.pinch))
    }

    // MARK: - SenderEvent Enum Tests

    func test_sender_event_control_case() {
        // Given
        let event = SenderEvent.control(.init(.touchUpInside))

        // Then
        if case .control(let control) = event {
            XCTAssertEqual(control.value, .touchUpInside)
        } else {
            XCTFail("Expected control case")
        }
    }

    func test_sender_event_gesture_case() {
        // Given
        let gestureEvent = SenderEvent.Gesture(
            kind: .tap,
            states: [.recognized]
        )

        // When
        let event = SenderEvent.gesture(gestureEvent)

        // Then
        if case .gesture(let gesture) = event {
            XCTAssertEqual(gesture.kind, .tap)
        } else {
            XCTFail("Expected gesture case")
        }
    }

    func test_sender_event_hashable() {
        // Given
        let event1 = SenderEvent.control(.init(.touchUpInside))
        let event2 = SenderEvent.control(.init(.touchUpInside))
        let event3 = SenderEvent.control(.init(.valueChanged))

        // Then
        XCTAssertEqual(event1, event2)
        XCTAssertNotEqual(event1, event3)

        // When
        var dict: [SenderEvent: [String]] = [:]
        dict[event1] = ["Hello, SendingState!"]

        // Then
        XCTAssertEqual(dict[event2], ["Hello, SendingState!"])
    }

    // MARK: - Specific Gesture Configurations

    func test_swipe_gesture_with_direction() {
        // When
        let gesture = SenderEvent.Gesture(
            kind: .swipe,
            states: [.recognized],
            direction: .right
        )

        // Then
        XCTAssertEqual(gesture.kind, .swipe)
        XCTAssertEqual(gesture.direction, .right)
    }

    func test_long_press_with_duration() {
        // When
        let gesture = SenderEvent.Gesture(
            kind: .longPress,
            states: [.began],
            minimumPressDuration: 1.4
        )

        // Then
        XCTAssertEqual(gesture.minimumPressDuration, 1.4)
    }

    func test_screen_edge_with_edges() {
        // When
        let gesture = SenderEvent.Gesture(
            kind: .screenEdge,
            states: [.recognized],
            edges: .left
        )

        // Then
        XCTAssertEqual(gesture.edges, .left)
    }

    func test_gesture_with_multiple_states() {
        // Given
        let states: Set<UIGestureRecognizer.State> = [.began, .changed, .ended]

        // When
        let gesture = SenderEvent.Gesture(
            kind: .pan,
            states: states
        )

        // Then
        XCTAssertEqual(gesture.states, states)
    }
}
#endif
