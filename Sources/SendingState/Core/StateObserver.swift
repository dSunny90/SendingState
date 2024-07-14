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
/// 3. Propagates the state to all senders for `EventForwarder` access
///
/// Attached to a binder (e.g., a `UIView`) as an associated object.
/// Uses weak references to the binder to prevent retain cycles.
@MainActor
internal final class StateObserver {
    /// Weak reference to the binder that owns this observer.
    weak var binder: NSObject?

    /// A closure that calls the binder's configurer with the given state.
    /// Captured with `[weak binder]` to prevent retain cycles.
    var configureBlock: ((Any) -> Void)?

    /// A closure that returns the current list of senders from the
    /// binder's `eventForwarder`. Evaluated lazily on each update.
    var senderProvider: (() -> [NSObject])?

    /// The current state value.
    var state: Any?

    /// Updates the state and triggers configuration + sender propagation.
    ///
    /// - Parameter newState: The new state value to store and propagate.
    func update(_ newState: Any) {
        state = newState
        binder?.boundState = newState
        configureBlock?(newState)
        for sender in senderProvider?() ?? [] {
            sender.boundState = newState
        }
    }
}
