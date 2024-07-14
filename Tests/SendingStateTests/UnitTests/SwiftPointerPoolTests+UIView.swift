//
//  SwiftPointerPoolTests+UIView.swift
//  SendingState
//
//  Created by SunSoo Jeon on 23.06.2023.
//

import XCTest
@testable import SendingState

#if os(iOS) || targetEnvironment(macCatalyst)
import UIKit

extension SwiftPointerPoolTests {
    // MARK: - Control Event Box Cleanup

    @MainActor
    func test_control_event_box_cleanup_removes_target() {
        // Given
        let button = UIButton()

        // When
        let box = UIControlSenderEventBox(
            control: button,
            on: .touchUpInside,
            actionHandler: { _ in }
        )

        // Then
        XCTAssertEqual(button.allTargets.count, 1)

        // When
        box.cleanup()

        let expectation = XCTestExpectation(description: "Cleanup")
        DispatchQueue.main.async {
            // Then
            XCTAssertEqual(button.allTargets.count, 0)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    @MainActor
    func test_multiple_control_boxes_cleanup() {
        // Given
        let aButton = UIButton()
        let aSwitch = UISwitch()
        let aSlider = UISlider()

        let box1 = UIControlSenderEventBox(
            control: aButton,
            on: .touchUpInside,
            actionHandler: { _ in }
        )
        let box2 = UIControlSenderEventBox(
            control: aSwitch,
            on: .valueChanged,
            actionHandler: { _ in }
        )
        let box3 = UIControlSenderEventBox(
            control: aSlider,
            on: .valueChanged,
            actionHandler: { _ in }
        )

        // When
        aButton.addToPointerPool(box1)
        aSwitch.addToPointerPool(box2)
        aSlider.addToPointerPool(box3)

        // Then
        XCTAssertEqual(aButton.allTargets.count, 1)
        XCTAssertEqual(aSwitch.allTargets.count, 1)
        XCTAssertEqual(aSlider.allTargets.count, 1)

        // When
        box1.cleanup()
        box2.cleanup()
        box3.cleanup()

        let expectation = XCTestExpectation(description: "All cleaned up")
        DispatchQueue.main.async {
            // Then
            XCTAssertEqual(aButton.allTargets.count, 0)
            XCTAssertEqual(aSwitch.allTargets.count, 0)
            XCTAssertEqual(aSlider.allTargets.count, 0)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - Gesture Event Box Cleanup

    @MainActor
    func test_gesture_event_box_cleanup() {
        // Given
        let gesture = UITapGestureRecognizer()
        let box = UIGestureRecognizerSenderEventBox(
            recognizer: gesture,
            on: [.recognized],
            actionHandler: { _ in }
        )

        // When
        box.cleanup()

        // Then: Should not crash after cleanup
        XCTAssertTrue(true)
    }

    // MARK: - Event Forwarding Provider

    @MainActor
    func test_event_forwarding_provider_sets_up_targets() {
        // Given
        let view = TestEventForwardingUIView()
        let handler = TestActionHandler()

        // When
        view.ss.addActionHandler(to: handler)

        // Then
        XCTAssertEqual(view.button.allTargets.count, 1)
        XCTAssertEqual(view.testSwitch.allTargets.count, 1)
        XCTAssertEqual(view.slider.allTargets.count, 1)
    }

    @MainActor
    func test_event_forwarding_triggers_action() {
        // Given
        let view = TestEventForwardingUIView()
        let handler = TestActionHandler()

        // When
        view.ss.addActionHandler(to: handler)
        TestActionTrigger.simulateControl(view.button, for: .touchUpInside)

        // Then
        XCTAssertEqual(handler.handledActions.count, 1)
    }

    // MARK: - Handler Replacement

    @MainActor
    func test_handler_replacement_works() {
        // Given
        let view = TestEventForwardingUIView()
        let handler1 = TestActionHandler()
        let handler2 = TestActionHandler()

        // When
        view.ss.addActionHandler(to: handler1)
        TestActionTrigger.simulateControl(view.button, for: .touchUpInside)

        // Then
        XCTAssertEqual(handler1.handledActions.count, 1)

        // When
        view.ss.addActionHandler(to: handler2)
        TestActionTrigger.simulateControl(view.button, for: .touchUpInside)

        // Then
        XCTAssertEqual(handler2.handledActions.count, 1)
    }

    // MARK: - Closure Capturing

    @MainActor
    func test_closure_captures_sender_correctly() {
        // Given
        let view = TestEventForwardingUIView()
        let handler = TestActionHandler()

        // When
        view.ss.addActionHandler(to: handler)
        view.button.tag = 90
        TestActionTrigger.simulateControl(view.button, for: .touchUpInside)

        // Then
        if case .buttonTapped(let tag) = handler.handledActions.first {
            XCTAssertEqual(tag, 90)
        } else {
            XCTFail("Expected buttonTapped action")
        }
    }

    // MARK: - TableView Cell Pattern

    @MainActor
    func test_table_view_cell_pattern() {
        class TestCell: UITableViewCell, EventForwardingProvider {
            let button = UIButton()

            var eventForwarder: EventForwardable {
                EventForwarder(button) { sender, ctx in
                    ctx.control(.touchUpInside) {
                        [TestAction.buttonTapped(sender.tag)]
                    }
                }
            }

            override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
                super.init(style: style, reuseIdentifier: reuseIdentifier)
                contentView.addSubview(button)
            }

            required init?(coder: NSCoder) {
                fatalError("init(coder:) has not been implemented")
            }
        }

        // Given
        let handler = TestActionHandler()

        // When
        for i in 0..<10 {
            let cell = TestCell(style: .default, reuseIdentifier: "Cell")
            cell.button.tag = i
            cell.ss.addActionHandler(to: handler)
            TestActionTrigger.simulateControl(cell.button, for: .touchUpInside)
        }

        // Then
        XCTAssertEqual(handler.handledActions.count, 10)

        for (index, action) in handler.handledActions.enumerated() {
            if case .buttonTapped(let tag) = action {
                XCTAssertEqual(tag, index)
            }
        }
    }
}
#endif
