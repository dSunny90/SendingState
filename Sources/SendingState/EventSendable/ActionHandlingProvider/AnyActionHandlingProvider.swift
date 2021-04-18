//
//  AnyActionHandlingProvider.swift
//  SendingState
//
//  Created by SunSoo Jeon on 18.04.2021.
//

/// A type-erased wrapper for `ActionHandlingProvider`.
///
/// Enables storage and handling of action handlers with different
/// associated action types, hiding the underlying concrete type.
public final class AnyActionHandlingProvider {
    private let _handle: (Any) -> Void

    /// Creates a type-erased action handler from a concrete provider.
    ///
    /// - Parameter base: The concrete `ActionHandlingProvider` to wrap.
    ///   Held weakly to avoid retain cycles.
    public init<T: ActionHandlingProvider>(_ base: T) {
        _handle = { [weak base] action in
            guard let base = base else { return }
            if let typedAction = action as? T.Action {
                base.handle(action: typedAction)
            }
        }
    }

    /// Handles a type-erased action.
    ///
    /// - Parameter action: The action to handle.
    public func handle(action: Any) {
        _handle(action)
    }
}

#if os(iOS) || targetEnvironment(macCatalyst)
import UIKit

extension AnyActionHandlingProvider {
    /// Attaches this handler to the view so it receives the view's
    /// forwarded events.
    ///
    /// - Parameter view: The view whose events this handler will receive.
    public func attach<V: UIView & EventSendingProvider>(to view: V) {
        view.ss.addAnyActionHandler(to: self)
    }

    /// Detaches this handler from the view, removing all event bindings
    /// that were previously established via ``attach(to:)``.
    ///
    /// After detaching, the view's events will no longer be forwarded
    /// to this handler.
    ///
    /// - Parameter view: The view to stop receiving events from.
    public func detach<V: UIView & EventSendingProvider>(from view: V) {
        view.ss.removeAnyActionHandler(from: self)
    }
}
#endif
