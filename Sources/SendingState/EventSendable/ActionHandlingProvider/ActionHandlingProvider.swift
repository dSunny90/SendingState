//
//  ActionHandlingProvider.swift
//  SendingState
//
//  Created by SunSoo Jeon on 2021/03/18.
//

/// A protocol for handling actions forwarded from UI components.
///
/// This protocol enables the separation of UI interactions from business logic
/// by centralizing action handling in dedicated objects.
public protocol ActionHandlingProvider: AnyObject {
    associatedtype Action

    /// Handles the forwarded action.
    ///
    /// Called when an action is dispatched from a UI component.
    ///
    /// - Parameter action: The action to handle.
    func handle(action: Action)
}
