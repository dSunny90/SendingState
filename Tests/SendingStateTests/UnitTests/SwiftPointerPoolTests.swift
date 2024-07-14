//
//  SwiftPointerPoolTests.swift
//  SendingState
//
//  Created by SunSoo Jeon on 23.06.2023.
//

import XCTest
@testable import SendingState

final class SwiftPointerPoolTests: XCTestCase {
    override func setUp() {
        super.setUp()
        TestAutoReleasable.resetCounters()
    }

    override func tearDown() {
        TestAutoReleasable.resetCounters()
        super.tearDown()
    }

    // MARK: - Insert and Find

    func test_pool_insert_stores_object() {
        // Given
        let pool = SwiftPointerPool()
        let obj = TestAutoReleasable(id: 11)

        // When
        pool.insert(obj)

        // Then
        let found = pool.find(ofType: TestAutoReleasable.self)
        XCTAssertNotNil(found)
        XCTAssertTrue(found === obj)
        XCTAssertEqual(found?.id, 11)
    }

    func test_pool_insert_multiple_objects() {
        // Given
        let pool = SwiftPointerPool()
        let obj1 = TestAutoReleasable(id: 11)
        let obj2 = TestAutoReleasable(id: 30)
        let obj3 = TestAutoReleasable(id: 90)

        // When
        pool.insert(obj1)
        pool.insert(obj2)
        pool.insert(obj3)

        // Then
        let found = pool.find(ofType: TestAutoReleasable.self)
        XCTAssertNotNil(found)
        XCTAssertEqual(found?.id, 11)
    }

    func test_pool_find_returns_nil_when_empty() {
        // Given
        let pool = SwiftPointerPool()

        // When
        let found = pool.find(ofType: TestAutoReleasable.self)

        // Then
        XCTAssertNil(found)
    }

    func test_pool_find_returns_nil_for_wrong_type() {
        class OtherType: AutoReleasable {
            var ownerIdentifier: ObjectIdentifier?

            func cleanup() {}
        }

        // Given
        let pool = SwiftPointerPool()
        let obj = TestAutoReleasable(id: 19)

        // When
        pool.insert(obj)

        // Then
        let found = pool.find(ofType: OtherType.self)
        XCTAssertNil(found)
    }

    // MARK: - Cleanup

    func test_pool_cleanup_calls_cleanup_on_all_objects() {
        // Given
        let pool = SwiftPointerPool()
        let obj1 = TestAutoReleasable(id: 1)
        let obj2 = TestAutoReleasable(id: 2)
        let obj3 = TestAutoReleasable(id: 3)

        // When
        pool.insert(obj1)
        pool.insert(obj2)
        pool.insert(obj3)
        pool.cleanup()

        // Then
        XCTAssertEqual(TestAutoReleasable.cleanupCallCount, 3)
        XCTAssertTrue(obj1.cleanupCalled)
        XCTAssertTrue(obj2.cleanupCalled)
        XCTAssertTrue(obj3.cleanupCalled)
    }

    func test_pool_cleanup_removes_all_objects() {
        // Given
        let pool = SwiftPointerPool()
        let obj1 = TestAutoReleasable(id: 3)
        let obj2 = TestAutoReleasable(id: 7)

        // When
        pool.insert(obj1)
        pool.insert(obj2)
        pool.cleanup()

        // Then
        let found = pool.find(ofType: TestAutoReleasable.self)
        XCTAssertNil(found)
    }

    func test_pool_cleanup_is_idempotent() {
        // Given
        let pool = SwiftPointerPool()
        let obj = TestAutoReleasable(id: 10)
        pool.insert(obj)

        // When
        pool.cleanup()

        // Then
        XCTAssertEqual(TestAutoReleasable.cleanupCallCount, 1)

        // When
        pool.cleanup()

        // Then
        XCTAssertEqual(TestAutoReleasable.cleanupCallCount, 1)
    }

    // MARK: - Owner-based Removal

    func test_pool_remove_by_owner_removes_only_matching_objects() {
        // Given
        let pool = SwiftPointerPool()
        let owner1 = NSObject()
        let owner2 = NSObject()
        let ownerID1 = ObjectIdentifier(owner1)
        let ownerID2 = ObjectIdentifier(owner2)

        let obj1 = TestAutoReleasable(id: 13)
        let obj2 = TestAutoReleasable(id: 23)
        let obj3 = TestAutoReleasable(id: 33)

        obj1.ownerIdentifier = ownerID1
        obj2.ownerIdentifier = ownerID1
        obj3.ownerIdentifier = ownerID2

        // When
        pool.insert(obj1)
        pool.insert(obj2)
        pool.insert(obj3)
        pool.remove(owner: ownerID1)

        // Then
        XCTAssertTrue(obj1.cleanupCalled)
        XCTAssertTrue(obj2.cleanupCalled)
        XCTAssertFalse(obj3.cleanupCalled)

        let found = pool.find(ofType: TestAutoReleasable.self)
        XCTAssertNotNil(found)
        XCTAssertEqual(found?.id, 33)
    }

    func test_pool_remove_by_owner_does_nothing_when_no_match() {
        // Given
        let pool = SwiftPointerPool()
        let owner1 = NSObject()
        let owner2 = NSObject()
        let ownerID1 = ObjectIdentifier(owner1)
        let ownerID2 = ObjectIdentifier(owner2)

        let obj1 = TestAutoReleasable(id: 43)
        obj1.ownerIdentifier = ownerID1

        // When
        pool.insert(obj1)
        pool.remove(owner: ownerID2)

        // Then
        XCTAssertFalse(obj1.cleanupCalled)
        XCTAssertNotNil(pool.find(ofType: TestAutoReleasable.self))
    }

    func test_pool_remove_by_owner_handles_nil_owner() {
        // Given
        let pool = SwiftPointerPool()
        let owner1 = NSObject()
        let ownerID1 = ObjectIdentifier(owner1)

        let obj1 = TestAutoReleasable(id: 23)
        let obj2 = TestAutoReleasable(id: 4)
        obj1.ownerIdentifier = ownerID1

        // When
        pool.insert(obj1)
        pool.insert(obj2)
        pool.remove(owner: ownerID1)

        // Then
        XCTAssertTrue(obj1.cleanupCalled)
        XCTAssertFalse(obj2.cleanupCalled)
    }

    // MARK: - Deinit Behavior

    func test_pool_deinit_triggers_cleanup() {
        // Given
        let obj1 = TestAutoReleasable(id: 119)
        let obj2 = TestAutoReleasable(id: 149)

        // When
        autoreleasepool {
            let pool = SwiftPointerPool()
            pool.insert(obj1)
            pool.insert(obj2)
        }

        // Then
        XCTAssertEqual(TestAutoReleasable.cleanupCallCount, 2)
        XCTAssertTrue(obj1.cleanupCalled)
        XCTAssertTrue(obj2.cleanupCalled)
    }

    func test_pool_retains_objects_until_cleanup() {
        // Given
        weak var weakObj: TestAutoReleasable?
        let pool = SwiftPointerPool()

        // When
        autoreleasepool {
            let obj = TestAutoReleasable(id: 1)
            weakObj = obj
            pool.insert(obj)
        }

        // Then
        XCTAssertNotNil(weakObj)
        XCTAssertEqual(TestAutoReleasable.instanceCount, 1)

        // When
        pool.cleanup()

        // Then
        XCTAssertEqual(TestAutoReleasable.instanceCount, 0)
    }

    // MARK: - Thread Safety

    func test_pool_thread_safe_concurrent_inserts() {
        // Given
        let pool = SwiftPointerPool()
        let expectation = XCTestExpectation(
            description: "Concurrent inserts"
        )

        let group = DispatchGroup()
        let queue = DispatchQueue.global(qos: .userInitiated)
        let iterations = 100

        // When
        for i in 0..<iterations {
            group.enter()
            queue.async {
                let obj = TestAutoReleasable(id: i)
                pool.insert(obj)
                group.leave()
            }
        }

        group.notify(queue: .main) {
            // Then
            XCTAssertNotNil(pool.find(ofType: TestAutoReleasable.self), "All objects should be inserted")
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 5.0)
    }

    func test_pool_thread_safe_concurrent_cleanup() {
        // Given
        let pool = SwiftPointerPool()

        // When
        for i in 0..<10 {
            pool.insert(TestAutoReleasable(id: i))
        }

        let expectation = XCTestExpectation(
            description: "Concurrent cleanup"
        )

        let group = DispatchGroup()
        let queue = DispatchQueue.global(qos: .userInitiated)

        for _ in 0..<10 {
            group.enter()
            queue.async {
                pool.cleanup()
                group.leave()
            }
        }

        group.notify(queue: .main) {
            // Then
            XCTAssertEqual(TestAutoReleasable.cleanupCallCount, 10, "Each object should be cleaned exactly once")
            XCTAssertNil(pool.find(ofType: TestAutoReleasable.self), "Pool should be empty after cleanup")
            XCTAssertEqual(TestAutoReleasable.instanceCount, 0, "All instances should be released after cleanup")
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 5.0)
    }

    func test_pool_thread_safety() {
        // Given
        let pool = SwiftPointerPool()
        let expectation = XCTestExpectation(description: "Pool thread safety")

        let group = DispatchGroup()
        let queue = DispatchQueue.global(qos: .userInitiated)

        // When
        for i in 0..<50 {
            group.enter()
            queue.async {
                let item = TestAutoReleasable(id: i)
                pool.insert(item)
                group.leave()
            }
        }

        group.notify(queue: .main) {
            // Then
            XCTAssertNotNil(pool.find(ofType: TestAutoReleasable.self), "the pool handles concurrent access and contains at least one item")
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 5.0)
    }
}
