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
