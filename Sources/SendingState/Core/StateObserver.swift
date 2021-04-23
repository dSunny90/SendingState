//
//  StateObserver.swift
//  SendingState
//
//  Created by SunSoo Jeon on 23.04.2021.
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

    /// Updates the state and triggers configuration
    ///
    /// - Parameter newState: The new state value to store
    func update(_ newState: Any) {
        state = newState
        binder?.boundState = newState
        configureBlock?(newState)
    }
}
