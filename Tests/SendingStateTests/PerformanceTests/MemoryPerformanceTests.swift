//
//  MemoryPerformanceTests.swift
//  SendingState
//
//  Created by SunSoo Jeon on 26.06.2023.
//

import XCTest
@testable import SendingState

#if os(iOS) || targetEnvironment(macCatalyst)
import UIKit

@MainActor
final class MemoryPerformanceTests: XCTestCase {

    // MARK: - SwiftPointerPool Performance

    /// Measure SwiftPointerPool insert performance
    func test_pointer_pool_insert_performance() {
        let pool = SwiftPointerPool()

        measure {
            for i in 0..<10000 {
                let item = SimpleAutoReleasable(id: i)
                pool.insert(item)
            }
        }
    }

    /// Measure SwiftPointerPool find performance
    func test_pointer_pool_find_performance() {
        let pool = SwiftPointerPool()

        // Pre-populate pool
        for i in 0..<1000 {
            pool.insert(SimpleAutoReleasable(id: i))
        }

        measure {
            for _ in 0..<10000 {
                _ = pool.find(ofType: SimpleAutoReleasable.self)
            }
        }
    }

    /// Measure SwiftPointerPool cleanup performance
    func test_pointer_pool_cleanup_performance() {
        measure {
            let pool = SwiftPointerPool()

            // Insert items
            for i in 0..<1000 {
                pool.insert(SimpleAutoReleasable(id: i))
            }

            // Cleanup
            pool.cleanup()
        }
    }

    // MARK: - NSObject Extension Performance

    /// Measure addToPointerPool performance
    func test_add_to_pointer_pool_performance() {
        let objects = (0..<1000).map { _ in NSObject() }
        let items = (0..<1000).map { SimpleAutoReleasable(id: $0) }

        measure {
            for (obj, item) in zip(objects, items) {
                obj.addToPointerPool(item)
            }
        }
    }

    // MARK: - Control Event Box Performance

    /// Measure UIControlSenderEventBox creation performance
    func test_control_event_box_creation_performance() {
        measure {
            for _ in 0..<10000 {
                let button = UIButton()
                _ = UIControlSenderEventBox(
                    control: button,
                    on: .touchUpInside,
                    actionHandler: { _ in }
                )
            }
        }
    }

    /// Measure control event box cleanup performance
    func test_control_event_box_cleanup_performance() {
        let buttons = (0..<1000).map { _ in UIButton() }
        let boxes = buttons.map { button in
            UIControlSenderEventBox(
                control: button,
                on: .touchUpInside,
                actionHandler: { _ in }
            )
        }

        measure {
            for box in boxes {
                box.cleanup()
            }
        }
    }

    // MARK: - Gesture Event Box Performance

    /// Measure UIGestureRecognizerSenderEventBox creation performance
    func test_gesture_event_box_creation_performance() {
        measure {
            for _ in 0..<10000 {
                let gesture = UITapGestureRecognizer()
                _ = UIGestureRecognizerSenderEventBox(
                    recognizer: gesture,
                    on: [.recognized],
                    actionHandler: { _ in }
                )
            }
        }
    }

    // MARK: - Memory Lifecycle

    /// Measure complete lifecycle memory performance
    func test_complete_lifecycle_memory_performance() {
        measure(metrics: [XCTMemoryMetric()]) {
            autoreleasepool {
                var views: [TestEventForwardingUIView] = []
                let handler = TestActionHandler()

                // Create and setup
                for _ in 0..<500 {
                    let view = TestEventForwardingUIView()
                    view.ss.addActionHandler(to: handler)
                    views.append(view)
                }

                // Use
                for view in views {
                    TestActionTrigger.simulateControl(view.button, for: .touchUpInside)
                }

                // Clear
                views.removeAll()
            }
        }
    }

    /// Measure memory usage during rapid view creation/destruction
    func test_rapid_view_lifecycle_memory() {
        let handler = TestActionHandler()

        measure(metrics: [XCTMemoryMetric()]) {
            for _ in 0..<1000 {
                autoreleasepool {
                    let view = TestEventForwardingUIView()
                    view.ss.addActionHandler(to: handler)
                    TestActionTrigger.simulateControl(view.button, for: .touchUpInside)
                }
            }
        }
    }

    // MARK: - TableView Cell Pattern

    /// Measure memory performance simulating cell reuse
    func test_cell_reuse_memory_performance() {
        class TestCell: UITableViewCell, EventForwardingProvider {
            let actionButton = UIButton()

            var eventForwarder: EventForwardable {
                EventForwarder(actionButton) { sender, ctx in
                    ctx.control(.touchUpInside) {
                        [TestAction.buttonTapped(sender.tag)]
                    }
                }
            }

            override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
                super.init(style: style, reuseIdentifier: reuseIdentifier)
                contentView.addSubview(actionButton)
            }

            required init?(coder: NSCoder) {
                fatalError("init(coder:) has not been implemented")
            }
        }

        let handler = TestActionHandler()

        measure(metrics: [XCTMemoryMetric()]) {
            // Simulate cell reuse pattern
            for cycle in 0..<100 {
                autoreleasepool {
                    var cells: [TestCell] = []

                    // Create visible cells
                    for i in 0..<200 {
                        let cell = TestCell(style: .default, reuseIdentifier: "Cell")
                        cell.actionButton.tag = cycle * 200 + i
                        cell.ss.addActionHandler(to: handler)
                        cells.append(cell)
                    }

                    // Simulate interactions
                    for cell in cells {
                        TestActionTrigger.simulateControl(cell.actionButton, for: .touchUpInside)
                    }

                    // Cells go out of scope (simulating scroll)
                }
            }
        }
    }

    // MARK: - Gesture Memory

    /// Measure memory with multiple gesture recognizers
    func test_gesture_memory_performance() {
        measure(metrics: [XCTMemoryMetric()]) {
            autoreleasepool {
                var views: [TestGestureUIView] = []
                let handler = TestActionHandler()

                for _ in 0..<500 {
                    let view = TestGestureUIView()
                    view.ss.addActionHandler(to: handler)
                    views.append(view)
                }

                views.removeAll()
            }
        }
    }

    // MARK: - Concurrent Memory Access

    /// Measure memory stability under concurrent access
    func test_concurrent_memory_stability() {
        let pool = SwiftPointerPool()
        let expectation = XCTestExpectation(description: "Concurrent access")

        measure {
            let group = DispatchGroup()
            let queue = DispatchQueue.global(qos: .userInitiated)

            for i in 0..<1000 {
                group.enter()
                queue.async {
                    let item = SimpleAutoReleasable(id: i)
                    pool.insert(item)
                    _ = pool.find(ofType: SimpleAutoReleasable.self)
                    group.leave()
                }
            }

            group.wait()
        }

        expectation.fulfill()
    }

    // MARK: - AnyActionHandlingProvider Memory

    /// Measure AnyActionHandlingProvider memory behavior
    func test_any_action_handling_provider_memory() {
        measure(metrics: [XCTMemoryMetric()]) {
            autoreleasepool {
                var handlers: [AnyActionHandlingProvider] = []

                for _ in 0..<1000 {
                    let handler = TestActionHandler()
                    let anyHandler = AnyActionHandlingProvider(handler)
                    handlers.append(anyHandler)

                    anyHandler.handle(action: TestAction.buttonTapped(1))
                }

                handlers.removeAll()
            }
        }
    }

    // MARK: - Boundable Memory

    /// Measure AnyBoundable memory overhead
    func test_any_boundable_memory_overhead() {
        measure(metrics: [XCTMemoryMetric()]) {
            var boundables: [AnyBoundable] = []

            for i in 0..<1000 {
                let boundable = TestBoundableViewModel(
                    contentData: TestConfigurableUIView.Model(text: "Item\(i)", value: i)
                ).eraseToAnyBoundable()
                boundables.append(boundable)
            }

            boundables.removeAll()
        }
    }
}

// MARK: - Test Helpers

private class SimpleAutoReleasable: AutoReleasable {
    var ownerIdentifier: ObjectIdentifier?
    
    let id: Int
    var cleanupCalled = false

    init(id: Int) {
        self.id = id
    }

    func cleanup() {
        cleanupCalled = true
    }
}
#endif
