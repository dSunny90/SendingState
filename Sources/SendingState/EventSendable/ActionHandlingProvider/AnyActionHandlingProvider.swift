//
//  AnyActionHandlingProvider.swift
//  SendingState
//
//  Created by SunSoo Jeon on 24.08.2021.
//

public final class AnyActionHandlingProvider {
    private let _handle: (Any) -> Void

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
    /// Internally attempts to cast the action to the expected type.
    public func handle(action: Any) {
        _handle(action)
    }
}
