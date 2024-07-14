//
//  AnyActionHandlingProviderTests+UIView.swift
//  SendingState
//
//  Created by SunSoo Jeon on 10.11.2022.
//

import XCTest
@testable import SendingState

#if os(iOS) || targetEnvironment(macCatalyst)
import UIKit
extension AnyActionHandlingProviderTests {
    // MARK: - Attach and Detach Methods

    @MainActor
    func test_attach_handler_to_view() {
        // Given
        let view = TestEventForwardingUIView()
        let handler = TestActionHandler()
        let anyHandler = AnyActionHandlingProvider(handler)

        // When
        anyHandler.attach(to: view)
        TestActionTrigger.simulateControl(view.button, for: .touchUpInside)

        // Then
        XCTAssertEqual(handler.handledActions.count, 1)
        XCTAssertTrue(handler.handledActions.first?.isButtonTap ?? false)
    }

    @MainActor
    func test_attach_multiple_handlers_to_same_view() {
        // Given
        let view = TestEventForwardingUIView()
        let handler1 = TestActionHandler()
        let handler2 = TestActionHandler()
        let anyHandler1 = AnyActionHandlingProvider(handler1)
        let anyHandler2 = AnyActionHandlingProvider(handler2)

        // When
        anyHandler1.attach(to: view)
        anyHandler2.attach(to: view)
        TestActionTrigger.simulateControl(view.button, for: .touchUpInside)

        // Then
        // handler1 should not receive actions (replaced)
        XCTAssertEqual(handler1.handledActions.count, 1)
        XCTAssertEqual(handler2.handledActions.count, 1)
    }

    @MainActor
    func test_attach_and_detach_handlers_to_view() {
        // Given
        let view = TestEventForwardingUIView()
        let handler = TestActionHandler()
        let anyHandler = AnyActionHandlingProvider(handler)

        // When
        anyHandler.attach(to: view)
        anyHandler.detach(from: view)
        TestActionTrigger.simulateControl(view.button, for: .touchUpInside)

        // Then
        XCTAssertEqual(handler.handledActions.count, 0)
    }

    // MARK: - Gesture Support

    @MainActor
    func test_any_handler_receives_gesture_actions() {
        // Given
        let view = TestGestureUIView()
        let handler = TestActionHandler()
        let anyHandler = AnyActionHandlingProvider(handler)

        // When
        anyHandler.attach(to: view)

        guard let tapGesture = view.view.gestureRecognizers?
            .first(where: { $0 is UITapGestureRecognizer }) as? UITapGestureRecognizer else {
            XCTFail("Tap gesture not attached")
            return
        }

        TestActionTrigger.simulateGestureRecognition(tapGesture)

        // Then
        XCTAssertEqual(handler.handledActions.count, 1)
        XCTAssertEqual(handler.handledActions.first, .viewTapped)
    }

    @MainActor
    func test_any_handler_receives_mixed_control_and_gesture_actions() {
        // Given
        let view = TestEventForwardingUIView()
        let handler = TestActionHandler()
        let anyHandler = AnyActionHandlingProvider(handler)

        // When
        anyHandler.attach(to: view)
        TestActionTrigger.simulateControl(view.button, for: .touchUpInside)
        guard let tapGesture = view.tapView.gestureRecognizers?
            .first(where: { $0 is UITapGestureRecognizer }) as? UITapGestureRecognizer else {
            XCTFail("Tap gesture not attached")
            return
        }
        TestActionTrigger.simulateGestureRecognition(tapGesture)

        // Then
        XCTAssertEqual(handler.handledActions.count, 2)
        XCTAssertTrue(handler.handledActions.contains(where: { $0.isButtonTap }))
        XCTAssertTrue(handler.handledActions.contains(.viewTapped))
    }

    // MARK: - Add, Remove, and Assign Methods

    @MainActor
    func test_add_any_action_handler_forwards_actions() {
        // Given
        let view = TestEventForwardingUIView()
        let handler = TestActionHandler()
        let anyHandler = AnyActionHandlingProvider(handler)

        // When
        view.ss.addAnyActionHandler(to: anyHandler)
        TestActionTrigger.simulateControl(view.button, for: .touchUpInside)

        // Then
        XCTAssertEqual(handler.handledActions.count, 1)
    }

    @MainActor
    func test_remove_any_action_handler_stops_forwarding() {
        // Given
        let view = TestEventForwardingUIView()
        let handler = TestActionHandler()
        let anyHandler = AnyActionHandlingProvider(handler)

        // When
        view.ss.addAnyActionHandler(to: anyHandler)
        view.ss.removeAnyActionHandler(from: anyHandler)
        TestActionTrigger.simulateControl(view.button, for: .touchUpInside)

        // Then
        XCTAssertEqual(handler.handledActions.count, 0)
    }

    @MainActor
    func test_assign_any_action_handler_replaces_existing() {
        // Given
        let view = TestEventForwardingUIView()
        let handler1 = TestActionHandler()
        let handler2 = TestActionHandler()
        let anyHandler1 = AnyActionHandlingProvider(handler1)
        let anyHandler2 = AnyActionHandlingProvider(handler2)

        // When
        view.ss.addAnyActionHandler(to: anyHandler1)
        view.ss.assignAnyActionHandler(to: anyHandler2)
        TestActionTrigger.simulateControl(view.button, for: .touchUpInside)

        // Then
        XCTAssertEqual(handler1.handledActions.count, 0)
        XCTAssertEqual(handler2.handledActions.count, 1)
    }

    // MARK: - Attach and Detach Methods

    @MainActor
    func test_attach() {
        // Given
        let view = TestEventForwardingUIView()
        let handler = TestActionHandler()
        let anyHandler = AnyActionHandlingProvider(handler)

        // When
        anyHandler.attach(to: view)
        TestActionTrigger.simulateControl(view.button, for: .touchUpInside)

        // Then
        XCTAssertEqual(handler.handledActions.count, 1)
    }

    @MainActor
    func test_attach_and_detach() {
        // Given
        let view = TestEventForwardingUIView()
        let handler = TestActionHandler()
        let anyHandler = AnyActionHandlingProvider(handler)

        // When
        anyHandler.attach(to: view)
        anyHandler.detach(from: view)
        TestActionTrigger.simulateControl(view.button, for: .touchUpInside)

        // Then
        XCTAssertEqual(handler.handledActions.count, 0)
    }

    @MainActor
    func test_detach_one_of_multiple_handlers_keeps_others() {
        // Given
        let view = TestEventForwardingUIView()
        let handler1 = TestActionHandler()
        let handler2 = TestActionHandler()
        let anyHandler1 = AnyActionHandlingProvider(handler1)
        let anyHandler2 = AnyActionHandlingProvider(handler2)

        // When
        anyHandler1.attach(to: view)
        anyHandler2.attach(to: view)
        anyHandler1.detach(from: view)
        TestActionTrigger.simulateControl(view.button, for: .touchUpInside)

        // Then
        XCTAssertEqual(handler1.handledActions.count, 0)
        XCTAssertEqual(handler2.handledActions.count, 1)
    }
}
#endif
