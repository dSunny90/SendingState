//
//  AnyActionHandlingProviderTests.swift
//  SendingState
//
//  Created by SunSoo Jeon on 10.11.2022.
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
