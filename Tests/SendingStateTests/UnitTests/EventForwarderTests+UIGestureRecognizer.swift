//
//  EventForwarderTests+UIGestureRecognizer.swift
//  SendingState
//
//  Created by SunSoo Jeon on 23.06.2023.
//

import XCTest
@testable import SendingState

#if os(iOS) || targetEnvironment(macCatalyst)
import UIKit

@MainActor
extension EventForwarderTests {
    // MARK: - Tap Gesture Setup

    func test_tap_gesture_is_attached_to_view() {
        // Given
        let view = TestFixture.makeView()

        // When
        let forwarder = EventForwarder(view) { _, ctx in
            ctx.tapGesture() {
                [TestAction.viewTapped]
            }
        }

        let provider = TestEventForwardableUIView(forwarder: forwarder)
        provider.addSubview(view)
        provider.ss.addActionHandler(to: TestActionHandler())

        // Then
        let tapGesture = view.gestureRecognizers?.first { $0 is UITapGestureRecognizer }
        XCTAssertNotNil(tapGesture, "Tap gesture should be attached to view")
    }

    func test_tap_gesture_configuration() {
        // Given
        let view = TestFixture.makeView()

        // When
        let forwarder = EventForwarder(view) { _, ctx in
            ctx.tapGesture(numberOfTaps: 5, numberOfTouches: 3) {
                [TestAction.custom("Double Tap")]
            }
        }

        let provider = TestEventForwardableUIView(forwarder: forwarder)
        provider.addSubview(view)
        provider.ss.addActionHandler(to: TestActionHandler())

        // Then
        guard let tapGesture = view.gestureRecognizers?
            .first(where: { $0 is UITapGestureRecognizer }) as? UITapGestureRecognizer else {
            XCTFail("Tap gesture not attached")
            return
        }

        XCTAssertEqual(tapGesture.numberOfTapsRequired, 5)
        XCTAssertEqual(tapGesture.numberOfTouchesRequired, 3)
    }

    func test_tap_gesture_forwards_action() {
        // Given
        let view = TestFixture.makeView()
        let handler = TestActionHandler()

        // When
        let forwarder = EventForwarder(view) { _, ctx in
            ctx.tapGesture() {
                [TestAction.viewTapped]
            }
        }

        let provider = TestEventForwardableUIView(forwarder: forwarder)
        provider.addSubview(view)
        provider.ss.addActionHandler(to: handler)

        guard let tapGesture = view.gestureRecognizers?
            .first(where: { $0 is UITapGestureRecognizer }) as? UITapGestureRecognizer else {
            XCTFail("Tap gesture not attached")
            return
        }

        TestActionTrigger.simulateGestureRecognition(tapGesture)

        // Then
        XCTAssertEqual(handler.handledActions.count, 1)
        XCTAssertEqual(handler.handledActions.first, .viewTapped)
    }

    // MARK: - Long Press Gesture Setup

    func test_long_press_gesture_is_attached_to_view() {
        // Given
        let view = TestFixture.makeView()

        // When
        let forwarder = EventForwarder(view) { _, ctx in
            ctx.longPressGesture() {
                [TestAction.longPressed]
            }
        }

        let provider = TestEventForwardableUIView(forwarder: forwarder)
        provider.addSubview(view)
        provider.ss.addActionHandler(to: TestActionHandler())

        // Then
        let gesture = view.gestureRecognizers?.first { $0 is UILongPressGestureRecognizer }
        XCTAssertNotNil(gesture, "Long press gesture should be attached")
    }

    func test_long_press_gesture_configuration() {
        // Given
        let view = TestFixture.makeView()

        // When
        let forwarder = EventForwarder(view) { _, ctx in
            ctx.longPressGesture(minimumPressDuration: 1.2, numberOfTaps: 7, numberOfTouches: 2) {
                [TestAction.longPressed]
            }
        }

        let provider = TestEventForwardableUIView(forwarder: forwarder)
        provider.addSubview(view)
        provider.ss.addActionHandler(to: TestActionHandler())

        // Then
        guard let gesture = view.gestureRecognizers?
            .first(where: { $0 is UILongPressGestureRecognizer }) as? UILongPressGestureRecognizer else {
            XCTFail("Long press gesture not attached")
            return
        }

        XCTAssertEqual(gesture.minimumPressDuration, 1.2, accuracy: 0.01)
        XCTAssertEqual(gesture.numberOfTapsRequired, 7)
        XCTAssertEqual(gesture.numberOfTouchesRequired, 2)
    }

    func test_long_press_gesture_forwards_action() {
        // Given
        let view = TestFixture.makeView()
        let handler = TestActionHandler()

        // When
        let forwarder = EventForwarder(view) { _, ctx in
            ctx.longPressGesture() {
                [TestAction.longPressed]
            }
        }

        let provider = TestEventForwardableUIView(forwarder: forwarder)
        provider.addSubview(view)
        provider.ss.addActionHandler(to: handler)

        guard let gesture = view.gestureRecognizers?
            .first(where: { $0 is UILongPressGestureRecognizer }) as? UILongPressGestureRecognizer else {
            XCTFail("Long press gesture not attached")
            return
        }

        TestActionTrigger.simulateGestureRecognition(gesture)

        // Then
        XCTAssertEqual(handler.handledActions.count, 1)
        XCTAssertEqual(handler.handledActions.first, .longPressed)
    }

    // MARK: - Pan Gesture Setup

    func test_pan_gesture_is_attached_to_view() {
        // Given
        let view = TestFixture.makeView()

        // When
        let forwarder = EventForwarder(view) { _, ctx in
            ctx.panGesture() {
                [TestAction.viewPanned]
            }
        }

        let provider = TestEventForwardableUIView(forwarder: forwarder)
        provider.addSubview(view)
        provider.ss.addActionHandler(to: TestActionHandler())

        // Then
        let gesture = view.gestureRecognizers?.first { $0 is UIPanGestureRecognizer }
        XCTAssertNotNil(gesture, "Pan gesture should be attached")
    }

    func test_pan_gesture_forwards_action() {
        // Given
        let view = TestFixture.makeView()
        let handler = TestActionHandler()

        // When
        let forwarder = EventForwarder(view) { _, ctx in
            ctx.panGesture() {
                [TestAction.viewPanned]
            }
        }

        let provider = TestEventForwardableUIView(forwarder: forwarder)
        provider.addSubview(view)
        provider.ss.addActionHandler(to: handler)

        guard let gesture = view.gestureRecognizers?
            .first(where: { $0 is UIPanGestureRecognizer }) as? UIPanGestureRecognizer else {
            XCTFail("Pan gesture not attached")
            return
        }

        TestActionTrigger.simulateGestureRecognition(gesture)

        // Then
        XCTAssertEqual(handler.handledActions.count, 1)
        XCTAssertEqual(handler.handledActions.first, .viewPanned)
    }

    // MARK: - Pinch Gesture Setup

    func test_pinch_gesture_is_attached_to_view() {
        // Given
        let view = TestFixture.makeView()

        // When
        let forwarder = EventForwarder(view) { _, ctx in
            ctx.pinchGesture() {
                [TestAction.viewPinched]
            }
        }

        let provider = TestEventForwardableUIView(forwarder: forwarder)
        provider.addSubview(view)
        provider.ss.addActionHandler(to: TestActionHandler())

        // Then
        let gesture = view.gestureRecognizers?.first { $0 is UIPinchGestureRecognizer }
        XCTAssertNotNil(gesture, "Pinch gesture should be attached")
    }

    func test_pinch_gesture_forwards_action() {
        // Given
        let view = TestFixture.makeView()
        let handler = TestActionHandler()

        // When
        let forwarder = EventForwarder(view) { _, ctx in
            ctx.pinchGesture() {
                [TestAction.viewPinched]
            }
        }

        let provider = TestEventForwardableUIView(forwarder: forwarder)
        provider.addSubview(view)
        provider.ss.addActionHandler(to: handler)

        guard let gesture = view.gestureRecognizers?
            .first(where: { $0 is UIPinchGestureRecognizer }) as? UIPinchGestureRecognizer else {
            XCTFail("Pinch gesture not attached")
            return
        }

        TestActionTrigger.simulateGestureRecognition(gesture)

        // Then
        XCTAssertEqual(handler.handledActions.count, 1)
        XCTAssertEqual(handler.handledActions.first, .viewPinched)
    }

    // MARK: - Swipe Gesture Setup

    func test_swipe_gesture_is_attached_to_view() {
        // Given
        let view = TestFixture.makeView()

        // When
        let forwarder = EventForwarder(view) { _, ctx in
            ctx.swipeGesture(direction: .left) {
                [TestAction.custom("Swipe Left")]
            }
        }

        let provider = TestEventForwardableUIView(forwarder: forwarder)
        provider.addSubview(view)
        provider.ss.addActionHandler(to: TestActionHandler())

        // Then
        guard let gesture = view.gestureRecognizers?
            .first(where: { $0 is UISwipeGestureRecognizer }) as? UISwipeGestureRecognizer else {
            XCTFail("Swipe gesture not attached")
            return
        }

        XCTAssertEqual(gesture.direction, .left)
    }

    func test_swipe_gesture_forwards_action() {
        // Given
        let view = TestFixture.makeView()
        let handler = TestActionHandler()

        // When
        let forwarder = EventForwarder(view) { _, ctx in
            ctx.swipeGesture(direction: .right) {
                [TestAction.custom("Swipe Right")]
            }
        }

        let provider = TestEventForwardableUIView(forwarder: forwarder)
        provider.addSubview(view)
        provider.ss.addActionHandler(to: handler)

        guard let gesture = view.gestureRecognizers?
            .first(where: { $0 is UISwipeGestureRecognizer }) as? UISwipeGestureRecognizer else {
            XCTFail("Swipe gesture not attached")
            return
        }

        TestActionTrigger.simulateGestureRecognition(gesture)

        // Then
        XCTAssertEqual(handler.handledActions.count, 1)
        XCTAssertEqual(handler.handledActions.first, .custom("Swipe Right"))
    }

    // MARK: - Rotation Gesture Setup

    func test_rotation_gesture_is_attached_to_view() {
        // Given
        let view = TestFixture.makeView()

        // When
        let forwarder = EventForwarder(view) { _, ctx in
            ctx.rotationGesture() {
                [TestAction.custom("Rotation")]
            }
        }

        let provider = TestEventForwardableUIView(forwarder: forwarder)
        provider.addSubview(view)
        provider.ss.addActionHandler(to: TestActionHandler())

        // Then
        let gesture = view.gestureRecognizers?.first { $0 is UIRotationGestureRecognizer }
        XCTAssertNotNil(gesture, "Rotation gesture should be attached")
    }

    func test_rotation_gesture_forwards_action() {
        // Given
        let view = TestFixture.makeView()
        let handler = TestActionHandler()

        // When
        let forwarder = EventForwarder(view) { _, ctx in
            ctx.rotationGesture() {
                [TestAction.custom("Rotation")]
            }
        }

        let provider = TestEventForwardableUIView(forwarder: forwarder)
        provider.addSubview(view)
        provider.ss.addActionHandler(to: handler)

        guard let gesture = view.gestureRecognizers?
            .first(where: { $0 is UIRotationGestureRecognizer }) as? UIRotationGestureRecognizer else {
            XCTFail("Rotation gesture not attached")
            return
        }

        TestActionTrigger.simulateGestureRecognition(gesture)

        // Then
        XCTAssertEqual(handler.handledActions.count, 1)
        XCTAssertEqual(handler.handledActions.first, .custom("Rotation"))
    }

    // MARK: - Multiple Gestures

    func test_multiple_gestures_attached_to_same_view() {
        // Given
        let view = TestFixture.makeView()

        // When
        let forwarder = EventForwarder(view) { _, ctx in
            ctx.tapGesture() { [TestAction.viewTapped] }
            ctx.pinchGesture() { [TestAction.viewPinched] }
            ctx.panGesture() { [TestAction.viewPanned] }
        }

        let provider = TestEventForwardableUIView(forwarder: forwarder)
        provider.addSubview(view)
        provider.ss.addActionHandler(to: TestActionHandler())

        // Then
        let gestures = view.gestureRecognizers ?? []
        XCTAssertEqual(gestures.count, 3)

        XCTAssertTrue(gestures.contains { $0 is UITapGestureRecognizer })
        XCTAssertTrue(gestures.contains { $0 is UIPinchGestureRecognizer })
        XCTAssertTrue(gestures.contains { $0 is UIPanGestureRecognizer })
    }

    func test_multiple_gestures_forward_actions() {
        // Given
        let view = TestFixture.makeView()
        let handler = TestActionHandler()

        // When
        let forwarder = EventForwarder(view) { _, ctx in
            ctx.tapGesture() { [TestAction.viewTapped] }
            ctx.pinchGesture() { [TestAction.viewPinched] }
            ctx.panGesture() { [TestAction.viewPanned] }
        }

        let provider = TestEventForwardableUIView(forwarder: forwarder)
        provider.addSubview(view)
        provider.ss.addActionHandler(to: handler)

        let gestures = view.gestureRecognizers ?? []

        // Trigger all gestures
        for gesture in gestures {
            if let tap = gesture as? UITapGestureRecognizer {
                TestActionTrigger.simulateGestureRecognition(tap)
            } else if let pinch = gesture as? UIPinchGestureRecognizer {
                TestActionTrigger.simulateGestureRecognition(pinch)
            } else if let pan = gesture as? UIPanGestureRecognizer {
                TestActionTrigger.simulateGestureRecognition(pan)
            }
        }

        // Then
        XCTAssertEqual(handler.handledActions.count, 3)
        XCTAssertTrue(handler.handledActions.contains(.viewTapped))
        XCTAssertTrue(handler.handledActions.contains(.viewPinched))
        XCTAssertTrue(handler.handledActions.contains(.viewPanned))
    }

    // MARK: - Gesture Target Registration

    func test_gesture_has_target_registered() {
        // Given
        let view = TestFixture.makeView()

        // When
        let forwarder = EventForwarder(view) { _, ctx in
            ctx.tapGesture() {
                [TestAction.viewTapped]
            }
        }

        let provider = TestEventForwardableUIView(forwarder: forwarder)
        provider.addSubview(view)
        provider.ss.addActionHandler(to: TestActionHandler())

        // Then
        guard let tapGesture = view.gestureRecognizers?.first else {
            XCTFail("No gesture attached")
            return
        }

        // Verify target is registered
        XCTAssertTrue(tapGesture.isEnabled)
        XCTAssertTrue(tapGesture.value(forKey: "targets") != nil)
    }

    // MARK: - SenderGroup with Gestures

    func test_sender_group_with_gestures_and_controls() {
        // Given
        let view = TestFixture.makeView()
        let button = UIButton()

        // When
        let group = SenderGroup {
            EventForwarder(view) { _, ctx in
                ctx.tapGesture() { [TestAction.viewTapped] }
            }
            EventForwarder(button) { sender, ctx in
                ctx.control(.touchUpInside) {
                    [TestAction.buttonTapped(sender.tag)]
                }
            }
        }

        // Then
        let mappings = group.allMappings
        XCTAssertEqual(mappings.count, 2)
    }

    // MARK: - Gesture Handler Management

    func test_remove_gesture_handler_stops_forwarding() {
        // Given
        let view = TestFixture.makeView()
        let handler = TestActionHandler()

        // When
        let forwarder = EventForwarder(view) { _, ctx in
            ctx.tapGesture() {
                [TestAction.viewTapped]
            }
        }

        let provider = TestEventForwardableUIView(forwarder: forwarder)
        provider.addSubview(view)
        provider.ss.addActionHandler(to: handler)

        // Capture gesture before removal
        guard let tapGesture = view.gestureRecognizers?
            .first(where: { $0 is UITapGestureRecognizer }) as? UITapGestureRecognizer else {
            XCTFail("Tap gesture not attached")
            return
        }

        provider.ss.removeActionHandler(from: handler)

        // Then
        let remainingTaps = view.gestureRecognizers?.filter { $0 is UITapGestureRecognizer } ?? []
        XCTAssertTrue(remainingTaps.isEmpty, "Gesture should be removed from view after handler removal")

        TestActionTrigger.simulateGestureRecognition(tapGesture)
        XCTAssertEqual(handler.handledActions.count, 0, "Even if triggered directly, the handler should not be called")
    }

    func test_assign_gesture_handler_replaces_existing() {
        // Given
        let view = TestFixture.makeView()
        let handler1 = TestActionHandler()
        let handler2 = TestActionHandler()

        // When
        let forwarder = EventForwarder(view) { _, ctx in
            ctx.tapGesture() {
                [TestAction.viewTapped]
            }
        }

        let provider = TestEventForwardableUIView(forwarder: forwarder)
        provider.addSubview(view)
        provider.ss.addActionHandler(to: handler1)
        provider.ss.assignActionHandler(to: handler2)

        guard let tapGesture = view.gestureRecognizers?
            .first(where: { $0 is UITapGestureRecognizer }) as? UITapGestureRecognizer else {
            XCTFail("Tap gesture not attached")
            return
        }

        TestActionTrigger.simulateGestureRecognition(tapGesture)

        // Then
        XCTAssertEqual(handler1.handledActions.count, 0)
        XCTAssertEqual(handler2.handledActions.count, 1)
    }


    // MARK: - TestGestureUIView Tests

    func test_mock_gesture_view_tap_forwards_action() {
        // Given
        let view = TestGestureUIView()
        let handler = TestActionHandler()

        // When
        view.ss.addActionHandler(to: handler)

        guard let tapGesture = view.view.gestureRecognizers?
            .first(where: { $0 is UITapGestureRecognizer }) as? UITapGestureRecognizer else {
            XCTFail("Tap gesture not attached")
            return
        }

        TestActionTrigger.simulateGestureRecognition(tapGesture)

        // Then
        XCTAssertTrue(handler.handledActions.contains(.viewTapped))
    }

    func test_mock_gesture_view_all_gestures_forward_actions() {
        // Given
        let view = TestGestureUIView()
        let handler = TestActionHandler()

        // When
        view.ss.addActionHandler(to: handler)

        let gestures = view.view.gestureRecognizers ?? []

        for gesture in gestures {
            if let tap = gesture as? UITapGestureRecognizer {
                TestActionTrigger.simulateGestureRecognition(tap)
            } else if let pinch = gesture as? UIPinchGestureRecognizer {
                TestActionTrigger.simulateGestureRecognition(pinch)
            } else if let pan = gesture as? UIPanGestureRecognizer {
                TestActionTrigger.simulateGestureRecognition(pan)
            } else if let longPress = gesture as? UILongPressGestureRecognizer {
                TestActionTrigger.simulateGestureRecognition(longPress)
            }
        }

        // Then
        XCTAssertTrue(handler.handledActions.contains(.viewTapped))
        XCTAssertTrue(handler.handledActions.contains(.viewPinched))
        XCTAssertTrue(handler.handledActions.contains(.viewPanned))
        XCTAssertTrue(handler.handledActions.contains(.longPressed))
    }
}
#endif
