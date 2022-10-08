//
//  ActionHandlingProvider.swift
//  SendingState
//
//  Created by SunSoo Jeon on 18.03.2021.
//

/// A protocol for handling actions forwarded from UI components.
///
/// Typically adopted by interactors or view controllers.
/// UI components conforming to `EventForwardingProvider` can forward
/// actions to this handler via `addActionHandler(to:)`.
///
/// This protocol enables the separation of UI interactions from business logic
/// by centralizing action handling in dedicated objects.
public protocol ActionHandlingProvider: AnyObject {
    associatedtype Action

    /// Called when an action is dispatched from a UI component.
    ///
    /// - Parameter action: The action to handle.
    func handle(action: Action)
}
