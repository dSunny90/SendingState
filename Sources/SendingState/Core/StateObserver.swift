//
//  StateObserver.swift
//  SendingState
//
//  Created by SunSoo Jeon on 14.12.2020.
//

import Foundation

/// Observes state changes and automatically triggers configuration updates.
///
/// When state is updated via ``update(_:)``, the observer:
/// 1. Stores the new state
/// 2. Calls the `configureBlock` to update the binder's UI
///
/// Attached to a binder (e.g., a `UIView`) as an associated object.
/// Uses weak references to the binder to prevent retain cycles.
internal final class StateObserver {
    /// Weak reference to the binder that owns this observer.
    weak var binder: NSObject?

    /// A closure that calls the binder's configurer with the given state.
    /// Captured with `[weak binder]` to prevent retain cycles.
    var configureBlock: ((Any) -> Void)?

    /// The current state value.
    var state: Any?

    /// A closure invoked whenever the observer processes a new state.
    private var changeHandler: ((Any) -> Void)?

    /// Sets a closure to be called whenever the observer's state changes.
    func setChangeHandler(_ handler: @escaping (Any) -> Void) {
        changeHandler = handler
    }

    /// Notifies the stored change handler closure of a state change.
    func notifyChange(with state: Any) {
        changeHandler?(state)
    }

    /// Updates the state and triggers configuration .
    ///
    /// - Parameter newState: The new state value to store.
    func update(_ newState: Any) {
        state = newState
        binder?.boundState = newState
        configureBlock?(newState)

        // Notify listeners about the incoming state
        changeHandler?(newState)
    }
}
