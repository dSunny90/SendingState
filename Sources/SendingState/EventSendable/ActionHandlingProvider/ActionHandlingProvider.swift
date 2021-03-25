//
//  ActionHandlingProvider.swift
//  SendingState
//
//  Created by SunSoo Jeon on 25.03.2021.
//

/// A class-only protocol that defines an action handler for UI events.
///
/// This protocol allows separation of UI interactions from business logic
/// by delegating action handling to dedicated objects.
public protocol ActionHandlingProvider: AnyObject {
    associatedtype Action
    /// Handles the given action.
    ///
    /// This method is typically called when an event occurs and an associated
    /// action is dispatched.
    ///
    /// - Parameter action: The action to be handled.
    func handle(action: Action)
}
