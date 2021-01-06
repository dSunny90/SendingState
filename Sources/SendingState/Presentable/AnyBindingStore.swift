//
//  AnyBindingStore.swift
//  SendingState
//
//  Created by SunSoo Jeon on 06.01.2021.
//

import Foundation

/// A type-erased wrapper around `BindingStore`.
///
/// `AnyBindingStore` makes it possible to store heterogeneous
/// `BindingStore<State, Binder>` instances in a single collection
/// while still exposing a unified interface for configuration,
/// state updates, size calculation, and state observation.
///
/// This wrapper strongly retains the underlying `BindingStore`.
open class AnyBindingStore {
    /// An optional identifier forwarded from the underlying store.
    public let identifier: String?

    /// The current type-erased state held by the underlying store.
    public var state: Any {
        get {
            _getStateBlock()
        }
        set {
            _setStateBlock(newValue)
        }
    }

    /// The current type-erased binder type associated with this store.
    public let binderType: Any.Type

    private let _getStateBlock: () -> Any
    private let _setStateBlock: (Any) -> Void
    private let _applyBlock: (Any) -> Void
    private let _observeBlock: (@escaping (Any) -> Void) -> StateObservationToken
    private let _sizeBlock: (CGSize?) -> CGSize?

    /// Creates a type-erased wrapper from a concrete `BindingStore`.
    ///
    /// - Parameter store: The concrete store to erase.
    public init<State, Binder>(_ store: BindingStore<State, Binder>) {
        identifier = store.identifier
        binderType = Binder.self

        _getStateBlock = { store.state }
        _setStateBlock = { newState in
            guard let newState = newState as? State else {
                assertionFailure(
                    "⚠️ [SendingState] AnyBindingStore.state received an incompatible state type. " +
                    "Expected \(State.self), got \(type(of: newState))."
                )
                return
            }

            store.state = newState
        }

        _applyBlock = { binder in
            guard let concreteBinder = binder as? Binder else {
                assertionFailure(
                    "⚠️ [SendingState] AnyBindingStore.apply(to:) received an incompatible binder type. " +
                    "Expected \(Binder.self), got \(type(of: binder))."
                )
                return
            }

            store.apply(to: concreteBinder)
        }

        _observeBlock = { observer in
            store.observe { value in
                observer(value)
            }
        }

        _sizeBlock = { size in
            return Binder.size(with: store.state, constrainedTo: size)
        }
    }

    /// Applies the underlying store state to the given binder.
    ///
    /// If the given binder does not match the underlying binder type,
    /// this method becomes a no-op in release builds and triggers an
    /// assertion in debug builds.
    ///
    /// - Parameter binder: A binder expected to match the wrapped
    ///                     store's binder type.
    public func apply(to binder: Any) {
        _applyBlock(binder)
    }

    /// Registers an observer for state changes from the underlying store.
    ///
    /// The observer receives the current state immediately upon registration.
    ///
    /// - Parameter observer: A closure invoked with type-erased state updates.
    /// - Returns: A token that controls the lifetime of the observation.
    @discardableResult
    public func observe(
        _ observer: @escaping (Any) -> Void
    ) -> StateObservationToken {
        _observeBlock(observer)
    }

    /// Calculates the size needed to display the current state.
    ///
    /// - Parameter size: An optional size constraint from the parent container.
    /// - Returns: The estimated size required to display the input,
    ///            or `nil` if no size calculation is needed.
    public func size(constrainedTo size: CGSize?) -> CGSize? {
        return _sizeBlock(size)
    }
}

extension AnyBindingStore: Hashable {
    public static func == (lhs: AnyBindingStore, rhs: AnyBindingStore) -> Bool {
        lhs === rhs
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
}
