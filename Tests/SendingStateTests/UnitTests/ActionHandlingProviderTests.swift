//
//  ActionHandlingProviderTests.swift
//  SendingState
//
//  Created by SunSoo Jeon on 23.06.2023.
//

import XCTest
@testable import SendingState

final class ActionHandlingProviderTests: XCTestCase {
    func test_handler_receives_action() {
        // Given
        let handler = TestActionHandler()

        // When
        handler.handle(action: .buttonTapped(90))

        // Then
        XCTAssertEqual(handler.callCount, 1)
        XCTAssertEqual(handler.handledActions.count, 1)
        XCTAssertEqual(handler.handledActions.first, .buttonTapped(90))
    }

    func test_handler_receives_multiple_actions() {
        // Given
        let handler = TestActionHandler()

        // When
        handler.handle(action: .buttonTapped(1))
        handler.handle(action: .switchChanged(true))
        handler.handle(action: .viewTapped)

        // Then
        XCTAssertEqual(handler.callCount, 3)
        XCTAssertEqual(handler.handledActions.count, 3)
    }

    func test_handler_maintains_action_order() {
        // Given
        let handler = TestActionHandler()
        let actions: [TestAction] = [
            .buttonTapped(1),
            .switchChanged(false),
            .sliderChanged(0.5),
            .viewTapped
        ]

        // When
        actions.forEach { handler.handle(action: $0) }

        // Then
        XCTAssertEqual(handler.handledActions, actions)
    }

    func test_handler_reset_clears_state() {
        // Given
        let handler = TestActionHandler()

        // When
        handler.handle(action: .buttonTapped(1))
        handler.handle(action: .viewTapped)
        handler.reset()

        // Then
        XCTAssertEqual(handler.callCount, 0)
        XCTAssertEqual(handler.handledActions.count, 0)
    }

    func test_handler_thread_safety() {
        // Given
        let expectation = XCTestExpectation(description: "Concurrent handler calls")
        let iterations = 50
        let handler = TestActionHandler()

        let group = DispatchGroup()
        let queue = DispatchQueue.global(qos: .userInitiated)

        // When
        for i in 0..<iterations {
            group.enter()
            queue.async {
                handler.handle(action: .buttonTapped(i))
                group.leave()
            }
        }

        group.notify(queue: .main) {
            // Then
            XCTAssertEqual(handler.handledActions.count, iterations)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 5.0)
    }

    func test_action_sendable_across_threads() {
        // Given
        let expectation = XCTestExpectation(description: "Sendable action")
        let handler = TestActionHandler()

        let action = TestAction.custom("Cross Thread")

        // When
        DispatchQueue.global().async {
            DispatchQueue.main.async {
                handler.handle(action: action)

                // Then
                XCTAssertEqual(handler.handledActions.last, .custom("Cross Thread"), "The handler records the action exactly as sent")
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 2.0)
    }
}
