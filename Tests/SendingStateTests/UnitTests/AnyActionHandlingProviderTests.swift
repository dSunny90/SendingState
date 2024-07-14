//
//  AnyActionHandlingProviderTests.swift
//  SendingState
//
//  Created by SunSoo Jeon on 23.06.2023.
//

import XCTest
@testable import SendingState

final class AnyActionHandlingProviderTests: XCTestCase {
    // MARK: - Type Erasure

    func test_type_erased_handler_forwards_correct_action() {
        // Given
        let handler = TestActionHandler()
        let anyHandler = AnyActionHandlingProvider(handler)

        // When
        anyHandler.handle(action: TestAction.buttonTapped(90))

        // Then
        XCTAssertEqual(handler.handledActions.count, 1)
        XCTAssertEqual(handler.handledActions.first, .buttonTapped(90))
    }

    func test_type_erased_handler_ignores_wrong_type() {
        // Given
        let handler = TestActionHandler()
        let anyHandler = AnyActionHandlingProvider(handler)

        // When
        anyHandler.handle(action: "WrongType")

        // Then
        XCTAssertEqual(handler.handledActions.count, 0, "Wrong type - should be ignored")
    }

    func test_type_erased_handler_forwards_multiple_actions() {
        // Given
        let handler = TestActionHandler()
        let anyHandler = AnyActionHandlingProvider(handler)

        // When
        anyHandler.handle(action: TestAction.buttonTapped(1))
        anyHandler.handle(action: TestAction.switchChanged(true))
        anyHandler.handle(action: TestAction.viewTapped)

        // Then
        XCTAssertEqual(handler.handledActions.count, 3)
    }

    // MARK: - Weak Reference

    func test_type_erased_handler_handles_action() {
        // Given
        let handler = TestActionHandler()
        let anyHandler = AnyActionHandlingProvider(handler)

        // When
        anyHandler.handle(action: TestAction.buttonTapped(1))

        // Then
        XCTAssertEqual(handler.handledActions.count, 1)
        XCTAssertEqual(handler.handledActions.first, .buttonTapped(1))
    }

    func test_type_erased_handler_no_crash_after_dealloc() {
        // Given
        var anyHandler: AnyActionHandlingProvider!

        autoreleasepool {
            let handler = TestActionHandler()
            anyHandler = AnyActionHandlingProvider(handler)
        }

        // When
        // Should not crash when handler is deallocated

        // Then
        XCTAssertNoThrow(
            anyHandler.handle(action: TestAction.buttonTapped(1))
        )
    }
}
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
}
#endif
