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
/// 3. Propagates the state to all senders for `EventForwarder` access
///
/// Attached to a binder (e.g., a `UIView`) as an associated object.
/// Uses weak references to the binder to prevent retain cycles.
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

    private var observers: [UUID: (Any) -> Void] = [:]

    /// Registers an observer and returns a token that controls its lifetime.
    ///
    /// The returned token must be retained for as long as the observation
    /// should remain active. Releasing or cancelling the token automatically
    /// removes the observer.
    ///
    /// - Parameters:
    ///   - notifyCurrentState: If `true` and a current state exists, the handler
    ///                         is called immediately with the current state upon
    ///                         registration. Defaults to `false`.
    ///   - handler: A closure invoked whenever a state change occurs.
    /// - Returns: A ``StateObservationToken`` that manages the lifetime of
    ///            this observation.
    @discardableResult
    func observe(
        notifyCurrentState: Bool = false,
        _ handler: @escaping (Any) -> Void
    ) -> StateObservationToken {
        let id = UUID()
        observers[id] = handler

        if notifyCurrentState, let state = state {
            handler(state)
        }

        return StateObservationToken { [weak self] in
            guard let self = self else { return }
            self.observers[id] = nil
        }
    }

    /// Notifies all registered observers of a state change.
    ///
    /// - Parameter state: The new state value to deliver to each observer.
    func notifyChange(with state: Any) {
        for observer in observers.values {
            observer(state)
        }
    }

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

        notifyChange(with: newState)
    }
}
