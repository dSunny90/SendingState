//
//  BindingStoreTests.swift
//  SendingState
//
//  Created by SunSoo Jeon on 07.01.2021.
//

import XCTest
@testable import SendingState

final class BindingStoreTests: XCTestCase {
    struct Model: Equatable {
        let title: String
        var count: Int
    }
}

#if os(iOS) || targetEnvironment(macCatalyst)
import UIKit

extension BindingStoreTests {
    final class TestBinder: UIView, Configurable {
        typealias Input = Model

        private(set) var configureCallCount = 0
        private(set) var lastInput: Model?

        var configurer: (TestBinder, Model) -> Void {
            { binder, input in
                binder.configureCallCount += 1
                binder.lastInput = input
            }
        }
    }

    func test_apply_configures_binder_with_state() {
        // Given
        let store = BindingStore<Model, TestBinder>(
            state: Model(title: "Test", count: 1)
        )
        let binder = TestBinder()

        // When
        store.apply(to: binder)

        // Then
        XCTAssertEqual(binder.configureCallCount, 1)
        XCTAssertEqual(binder.lastInput, Model(title: "Test", count: 1))
    }

    func test_apply_stores_state_on_binder() {
        // Given
        let store = BindingStore<Model, TestBinder>(
            state: Model(title: "Hello, World!", count: 2)
        )
        let binder = TestBinder()

        // When
        store.apply(to: binder)

        // Then
        let state: Model? = binder.ss.state()
        XCTAssertEqual(state, Model(title: "Hello, World!", count: 2))
    }

    // MARK: - Binder -> Parent Sync

    func test_invalidateState_from_binder_updates_store_state() {
        // Given
        let store = BindingStore<Model, TestBinder>(
            state: Model(title: "Sunny", count: 3)
        )
        let binder = TestBinder()
        store.apply(to: binder)

        // When
        binder.ss.invalidateState { (state: Model) in
            var newState = state
            newState.count += 1
            return newState
        }

        // Then
        XCTAssertEqual(store.state, Model(title: "Sunny", count: 4))
    }

    func test_invalidateState_from_binder_reconfigures_binder() {
        // Given
        let store = BindingStore<Model, TestBinder>(
            state: Model(title: "Swift", count: 1)
        )
        let binder = TestBinder()
        store.apply(to: binder)

        XCTAssertEqual(binder.configureCallCount, 1)
        XCTAssertEqual(binder.lastInput, Model(title: "Swift", count: 1))

        // When
        binder.ss.invalidateState { (state: Model) in
            var newState = state
            newState.count = 5
            return newState
        }

        // Then
        XCTAssertEqual(binder.configureCallCount, 2)
        XCTAssertEqual(binder.lastInput, Model(title: "Swift", count: 5))
    }

    func test_invalidateState_from_binder_updates_binder_state() {
        // Given
        let store = BindingStore<Model, TestBinder>(
            state: Model(title: "Objective-C", count: 3)
        )
        let binder = TestBinder()
        store.apply(to: binder)

        // When
        binder.ss.invalidateState { (state: Model) in
            var newState = state
            newState.count = 7
            return newState
        }

        // Then
        let state: Model? = binder.ss.state()
        XCTAssertEqual(state, Model(title: "Objective-C", count: 7))
    }

    func test_update_replaces_state() {
        // Given
        let store = BindingStore<Model, TestBinder>(
            state: Model(title: "Test", count: 1)
        )

        // When
        store.state = Model(title: "Test", count: 10)

        // Then
        XCTAssertEqual(store.state, Model(title: "Test", count: 10))
    }

    func test_store_and_binder_can_be_released_after_apply() {
        weak var weakStore: BindingStore<Model, TestBinder>?
        weak var weakBinder: TestBinder?

        autoreleasepool {
            let store = BindingStore<Model, TestBinder>(
                state: Model(title: "Test", count: 11)
            )
            let binder = TestBinder()

            store.apply(to: binder)

            weakStore = store
            weakBinder = binder
        }

        XCTAssertNil(weakStore)
        XCTAssertNil(weakBinder)
    }
}
#endif
