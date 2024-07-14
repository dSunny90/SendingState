//
//  ActionHandlingProviderTests+UIView.swift
//  SendingState
//
//  Created by SunSoo Jeon on 23.06.2023.
//

import XCTest
@testable import SendingState

#if os(iOS) || targetEnvironment(macCatalyst)
import UIKit
extension ActionHandlingProviderTests {
    // MARK: - Add Action Handler

    @MainActor
    func test_add_action_handler_registers_targets() {
        // Given
        let view = TestEventForwardingUIView()
        let handler = TestActionHandler()

        // When
        view.ss.addActionHandler(to: handler)

        // Then
        XCTAssertEqual(view.button.allTargets.count, 1)
    }

    @MainActor
    func test_add_action_handler_forwards_actions() {
        // Given
        let view = TestEventForwardingUIView()
        let handler = TestActionHandler()

        // When
        view.ss.addActionHandler(to: handler)
        TestActionTrigger.simulateControl(view.button, for: .touchUpInside)

        // Then
        XCTAssertEqual(handler.handledActions.count, 1)
        XCTAssertTrue(handler.handledActions.first?.isButtonTap ?? false)
    }

    @MainActor
    func test_add_multiple_handlers() {
        // Given
        let view = TestEventForwardingUIView()
        let handler1 = TestActionHandler()
        let handler2 = TestActionHandler()

        // When
        view.ss.addActionHandler(to: handler1)
        view.ss.addActionHandler(to: handler2)
        TestActionTrigger.simulateControl(view.button, for: .touchUpInside)

        // Then
        XCTAssertEqual(handler1.handledActions.count, 1, "Both handlers should receive the action")
        XCTAssertEqual(handler2.handledActions.count, 1, "Both handlers should receive the action")
    }

    @MainActor
    func test_add_same_handler_twice_creates_duplicate() {
        // Given
        let view = TestEventForwardingUIView()
        let handler = TestActionHandler()

        // When
        view.ss.addActionHandler(to: handler)
        view.ss.addActionHandler(to: handler)
        TestActionTrigger.simulateControl(view.button, for: .touchUpInside)

        // Then
        XCTAssertEqual(handler.handledActions.count, 1)
    }

    // MARK: - Remove Action Handler

    @MainActor
    func test_remove_action_handler_stops_forwarding() {
        // Given
        let view = TestEventForwardingUIView()
        let handler = TestActionHandler()

        // When
        view.ss.addActionHandler(to: handler)
        view.ss.removeActionHandler(from: handler)
        TestActionTrigger.simulateControl(view.button, for: .touchUpInside)

        // Then
        XCTAssertEqual(handler.handledActions.count, 0)
    }

    @MainActor
    func test_remove_specific_handler_keeps_others() {
        // Given
        let view = TestEventForwardingUIView()
        let handler1 = TestActionHandler()
        let handler2 = TestActionHandler()

        // When
        view.ss.addActionHandler(to: handler1)
        view.ss.addActionHandler(to: handler2)
        view.ss.removeActionHandler(from: handler1)
        TestActionTrigger.simulateControl(view.button, for: .touchUpInside)

        // Then
        XCTAssertEqual(handler1.handledActions.count, 0, "Only handler2 should receive the action")
        XCTAssertEqual(handler2.handledActions.count, 1)
    }

    @MainActor
    func test_remove_nonexistent_handler_does_nothing() {
        // Given
        let view = TestEventForwardingUIView()
        let handler1 = TestActionHandler()
        let handler2 = TestActionHandler()

        // When
        view.ss.addActionHandler(to: handler1)
        view.ss.removeActionHandler(from: handler2)
        TestActionTrigger.simulateControl(view.button, for: .touchUpInside)

        // Then
        XCTAssertEqual(handler1.handledActions.count, 1)
    }

    // MARK: - Remove All Action Handlers

    @MainActor
    func test_remove_all_action_handlers_stops_all_forwarding() {
        // Given
        let view = TestEventForwardingUIView()
        let handler1 = TestActionHandler()
        let handler2 = TestActionHandler()

        // When
        view.ss.addActionHandler(to: handler1)
        view.ss.addActionHandler(to: handler2)
        view.ss.removeAllActionHandlers()
        TestActionTrigger.simulateControl(view.button, for: .touchUpInside)

        // Then
        XCTAssertEqual(handler1.handledActions.count, 0)
        XCTAssertEqual(handler2.handledActions.count, 0)
    }

    @MainActor
    func test_remove_all_on_empty_view_does_nothing() {
        // Given
        let view = TestEventForwardingUIView()

        // When
        // Removing all on an empty view

        // Then
        XCTAssertNoThrow(view.ss.removeAllActionHandlers())
    }

    // MARK: - Assign Action Handler

    @MainActor
    func test_assign_action_handler_replaces_all_existing() {
        // Given
        let view = TestEventForwardingUIView()
        let handler1 = TestActionHandler()
        let handler2 = TestActionHandler()
        let handler3 = TestActionHandler()

        // When
        view.ss.addActionHandler(to: handler1)
        view.ss.addActionHandler(to: handler2)
        view.ss.assignActionHandler(to: handler3)
        TestActionTrigger.simulateControl(view.button, for: .touchUpInside)

        // Then
        XCTAssertEqual(handler1.handledActions.count, 0)
        XCTAssertEqual(handler2.handledActions.count, 0)
        XCTAssertEqual(handler3.handledActions.count, 1)
    }

    @MainActor
    func test_assign_on_empty_view_adds_handler() {
        // Given
        let view = TestEventForwardingUIView()
        let handler = TestActionHandler()

        // When
        view.ss.assignActionHandler(to: handler)
        TestActionTrigger.simulateControl(view.button, for: .touchUpInside)

        // Then
        XCTAssertEqual(handler.handledActions.count, 1)
    }

    @MainActor
    func test_assign_same_handler_only_registers_once() {
        // Given
        let view = TestEventForwardingUIView()
        let handler = TestActionHandler()

        // When
        view.ss.assignActionHandler(to: handler)
        view.ss.assignActionHandler(to: handler)
        TestActionTrigger.simulateControl(view.button, for: .touchUpInside)

        // Then
        XCTAssertEqual(handler.handledActions.count, 1, "Should only receive once (assign removes all then adds)")
    }

    // MARK: - Any Action Handler Variants

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

    // MARK: - Multiple Controls

    @MainActor
    func test_handler_receives_from_multiple_controls() {
        // Given
        let view = TestEventForwardingUIView()
        let handler = TestActionHandler()

        // When
        view.button.tag = 90
        view.ss.addActionHandler(to: handler)
        TestActionTrigger.simulateControl(view.button, for: .touchUpInside)
        TestActionTrigger.simulateSwitch(view.testSwitch, flag: true)
        TestActionTrigger.simulateSlider(view.slider, value: 0.74)

        // Then
        XCTAssertEqual(handler.handledActions.count, 3)
        XCTAssertEqual(handler.handledActions[0], .buttonTapped(90))
        XCTAssertEqual(handler.handledActions[1], .switchChanged(true))
        XCTAssertEqual(handler.handledActions[2], .sliderChanged(0.74))
    }

    @MainActor
    func test_remove_all_affects_all_controls() {
        // Given
        let view = TestEventForwardingUIView()
        let handler = TestActionHandler()

        // When
        view.ss.addActionHandler(to: handler)
        view.ss.removeAllActionHandlers()
        TestActionTrigger.simulateControl(view.button, for: .touchUpInside)
        TestActionTrigger.simulateSwitch(view.testSwitch, flag: true)

        // Then
        XCTAssertEqual(handler.handledActions.count, 0)
    }

    @MainActor
    func test_concurrent_event_triggering() {
        // Given
        let view = TestEventForwardingUIView()
        let handler = TestActionHandler()
        view.ss.addActionHandler(to: handler)
        let expectation = XCTestExpectation(description: "Concurrent access")

        let group = DispatchGroup()

        // When
        for _ in 0..<50 {
            group.enter()
            DispatchQueue.main.async {
                TestActionTrigger.simulateControl(view.button, for: .touchUpInside)
                group.leave()
            }
        }

        group.notify(queue: .main) {
            // Then
            XCTAssertEqual(handler.handledActions.count, 50, "All actions are handled without race")
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 2.0)
    }

    func test_rapid_handler_replacement() {
        let view = TestEventForwardingUIView()
        let handlers = (0..<10).map { _ in TestActionHandler() }
        let lastHandler = handlers.last!

        // Given
        let expectation = XCTestExpectation(description: "Rapid replacement")
        let group = DispatchGroup()

        // When
        for handler in handlers {
            group.enter()
            DispatchQueue.main.async {
                view.ss.addActionHandler(to: handler)
                TestActionTrigger.simulateControl(view.button, for: .touchUpInside)
                group.leave()
            }
        }

        group.notify(queue: .main) {
            // Then
            XCTAssertTrue(lastHandler.handledActions.count >= 1, "Should not crash and the last handler should receive at least one action")
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 5.0)
    }
}
#endif
