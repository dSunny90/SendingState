//
//  AnyBindingStoreTests.swift
//  SendingState
//
//  Created by SunSoo Jeon on 07.01.2021.
//

import XCTest
@testable import SendingState

final class AnyBindingStoreTests: XCTestCase {
    struct ProductModel: Equatable {
        let name: String
        var count: Int
    }

    struct BannerModel: Equatable {
        let title: String
        var order: Int
    }
}

#if os(iOS) || targetEnvironment(macCatalyst)
import UIKit

@MainActor
extension AnyBindingStoreTests {
    final class ProductView: UIView, Configurable {
        typealias Input = ProductModel

        private(set) var configureCallCount = 0
        private(set) var lastInput: ProductModel?

        var configurer: (ProductView, ProductModel) -> Void {
            { cell, input in
                cell.configureCallCount += 1
                cell.lastInput = input
            }
        }
    }

    final class BannerView: UIView, Configurable {
        typealias Input = BannerModel

        private(set) var configureCallCount = 0
        private(set) var lastInput: BannerModel?

        var configurer: (BannerView, BannerModel) -> Void {
            { cell, input in
                cell.configureCallCount += 1
                cell.lastInput = input
            }
        }
    }

    func test_state_forwards_from_underlying_store() {
        // Given
        let model = ProductModel(name: "Shirt", count: 2)
        let store = BindingStore<ProductModel, ProductView>(state: model)
        let anyStore = AnyBindingStore(store)

        // When
        let state: ProductModel? = anyStore.state as? ProductModel

        // Then
        XCTAssertEqual(state, model)
    }

    func test_apply_configures_matching_binder_and_invalidatestate() {
        // Given
        let model = ProductModel(name: "Pants", count: 11)
        let store = BindingStore<ProductModel, ProductView>(state: model)
        let anyStore = AnyBindingStore(store)
        let binder = ProductView()

        // When
        anyStore.apply(to: binder)

        // Then
        XCTAssertEqual(binder.configureCallCount, 1)
        XCTAssertEqual(binder.lastInput, model)

        // When
        binder.ss.invalidateState { state in
            ProductModel(name: "Socks", count: 30)
        }

        // Then
        XCTAssertEqual(binder.ss.state()?.count, 30)
        XCTAssertEqual(store.state.count, 30)
        XCTAssertEqual((anyStore.state as? ProductModel)?.count, 30)
    }

//    func test_apply_does_nothing_for_non_matching_binder_type() {
//        // Given
//        let model = ProductModel(name: "Coat", count: 23)
//        let store = BindingStore<ProductModel, ProductView>(state: model)
//        let anyStore = AnyBindingStore(store)
//        let wrongBinder = BannerView()
//
//        // When (assertionFailure)
//        anyStore.apply(to: wrongBinder)
//
//        // Then
//        XCTAssertEqual(wrongBinder.configureCallCount, 0)
//        XCTAssertNil(wrongBinder.lastInput)
//    }

    func test_update_updates_underlying_store_when_type_matches() {
        // Given
        let initial = ProductModel(name: "e-Book", count: 1)
        let updated = ProductModel(name: "Album", count: 7)

        let store = BindingStore<ProductModel, ProductView>(state: initial)
        let anyStore = AnyBindingStore(store)

        // When
        anyStore.state = updated

        // Then
        XCTAssertEqual(store.state, updated)
        let state: ProductModel? = anyStore.state as? ProductModel
        XCTAssertEqual(state, updated)
    }

//    func test_update_does_nothing_when_type_does_not_match() {
//        // Given
//        let initial = ProductModel(name: "Sneakers", count: 1)
//
//        let store = BindingStore<ProductModel, ProductView>(state: initial)
//        let anyStore = AnyBindingStore(store)
//
//        // When (assertionFailure)
//        anyStore.update(BannerModel(title: "Event Banner", order: 2))
//
//        // Then
//        XCTAssertEqual(store.state(), initial)
//    }

    func test_heterogeneous_anyBindingStore_collection() {
        // Given
        let appleStore = BindingStore<ProductModel, ProductView>(
            state: ProductModel(name: "Apple", count: 1)
        )
        let iPhoneStore = BindingStore<BannerModel, BannerView>(
            state: BannerModel(title: "iPhone", order: 2)
        )

        // When
        let stores: [AnyBindingStore] = [
            AnyBindingStore(appleStore),
            AnyBindingStore(iPhoneStore)
        ]

        // Then
        XCTAssertEqual(stores.count, 2)
        XCTAssertEqual((stores[0].state as? ProductModel)?.name, "Apple")
        XCTAssertEqual((stores[1].state as? BannerModel)?.title, "iPhone")
    }

    func test_anyBindingStore_and_underlying_store_are_released() {
        weak var weakStore: BindingStore<ProductModel, ProductView>?
        weak var weakAnyStore: AnyBindingStore?

        autoreleasepool {
            let store = BindingStore<ProductModel, ProductView>(
                state: ProductModel(name: "Banana", count: 11)
            )
            let anyStore = AnyBindingStore(store)

            weakStore = store
            weakAnyStore = anyStore

            XCTAssertNotNil(weakStore)
            XCTAssertNotNil(weakAnyStore)
        }

        XCTAssertNil(weakStore)
        XCTAssertNil(weakAnyStore)
    }

    func test_anyBindingStore_store_and_binder_are_released_after_apply() {
        weak var weakStore: BindingStore<ProductModel, ProductView>?
        weak var weakAnyStore: AnyBindingStore?
        weak var weakBinder: ProductView?

        autoreleasepool {
            let store = BindingStore<ProductModel, ProductView>(
                state: ProductModel(name: "Chocolate", count: 1)
            )
            let anyStore = AnyBindingStore(store)
            let binder = ProductView()

            anyStore.apply(to: binder)

            weakStore = store
            weakAnyStore = anyStore
            weakBinder = binder

            XCTAssertNotNil(weakStore)
            XCTAssertNotNil(weakAnyStore)
            XCTAssertNotNil(weakBinder)
        }

        XCTAssertNil(weakStore)
        XCTAssertNil(weakAnyStore)
        XCTAssertNil(weakBinder)
    }

    func test_anyBindingStore_store_and_binder_are_released_after_invalidateState() {
        weak var weakStore: BindingStore<ProductModel, ProductView>?
        weak var weakAnyStore: AnyBindingStore?
        weak var weakBinder: ProductView?

        autoreleasepool {
            let store = BindingStore<ProductModel, ProductView>(
                state: ProductModel(name: "Milk", count: 1)
            )
            let anyStore = AnyBindingStore(store)
            let binder = ProductView()

            anyStore.apply(to: binder)

            binder.ss.invalidateState { (state: ProductModel) in
                var newState = state
                newState.count += 1
                return newState
            }

            weakStore = store
            weakAnyStore = anyStore
            weakBinder = binder

            XCTAssertEqual(store.state, ProductModel(name: "Milk", count: 2))
        }

        XCTAssertNil(weakStore)
        XCTAssertNil(weakAnyStore)
        XCTAssertNil(weakBinder)
    }

    func test_old_store_is_released_when_same_binder_is_rebound_to_new_anyBindingStore() {
        weak var weakOldStore: BindingStore<ProductModel, ProductView>?
        weak var weakOldAnyStore: AnyBindingStore?

        autoreleasepool {
            let binder = ProductView()

            do {
                let oldStore = BindingStore<ProductModel, ProductView>(
                    state: ProductModel(name: "Soboro Bread", count: 11)
                )
                let oldAnyStore = AnyBindingStore(oldStore)

                oldAnyStore.apply(to: binder)

                weakOldStore = oldStore
                weakOldAnyStore = oldAnyStore

                XCTAssertNotNil(weakOldStore)
                XCTAssertNotNil(weakOldAnyStore)
            }

            let newStore = BindingStore<ProductModel, ProductView>(
                state: ProductModel(name: "Cream Bread", count: 30)
            )
            let newAnyStore = AnyBindingStore(newStore)

            newAnyStore.apply(to: binder)

            _ = newStore
            _ = newAnyStore
        }

        XCTAssertNil(weakOldStore)
        XCTAssertNil(weakOldAnyStore)
    }

    func test_anyBindingStore_observation_token_does_not_prevent_release_after_cancel() {
        weak var weakStore: BindingStore<ProductModel, ProductView>?
        weak var weakAnyStore: AnyBindingStore?

        autoreleasepool {
            let store = BindingStore<ProductModel, ProductView>(
                state: ProductModel(name: "Coffee", count: 4)
            )
            let anyStore = AnyBindingStore(store)

            let token = anyStore.observe { _ in }
            token.cancel()

            weakStore = store
            weakAnyStore = anyStore

            XCTAssertNotNil(weakStore)
            XCTAssertNotNil(weakAnyStore)
        }

        XCTAssertNil(weakStore)
        XCTAssertNil(weakAnyStore)
    }

    func test_anyBindingStore_observation_token_does_not_prevent_release_without_manual_cancel() {
        weak var weakStore: BindingStore<ProductModel, ProductView>?
        weak var weakAnyStore: AnyBindingStore?

        autoreleasepool {
            let store = BindingStore<ProductModel, ProductView>(
                state: ProductModel(name: "Water", count: 23)
            )
            let anyStore = AnyBindingStore(store)

            _ = anyStore.observe { _ in }

            weakStore = store
            weakAnyStore = anyStore

            XCTAssertNotNil(weakStore)
            XCTAssertNotNil(weakAnyStore)
        }

        XCTAssertNil(weakStore)
        XCTAssertNil(weakAnyStore)
    }
}
#endif
