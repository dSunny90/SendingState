//
//  EventForwarder.swift
//  SendingState
//
//  Created by SunSoo Jeon on 13.03.2021.
//

/// A type that maps events from a specific sender to actions.
///
/// `EventForwarder` captures a sender and defines mappings from its events
/// to the actions forwarded when those events occur.
///
/// Use `EventForwarder` to define event behavior for a specific sender.
public struct EventForwarder<Action> {
    /// The sender whose events to forward.
    public let sender: AnyObject

    /// The mappings from sender events to their corresponding action providers.
    /// Closures are stored to enable lazy evaluation at event time,
    /// allowing actions to capture real-time sender state.
    public let mappings: [SenderEvent: () -> [Action]]

    public var allMappings: [
        (sender: AnyObject, event: SenderEvent, actions: [Action])
    ] {
        mappings.map { (sender: self.sender, event: $0.key, actions: $0.value()) }
    }

    /// Returns the actions mapped to the given event.
    public func actions(for event: SenderEvent) -> [Action] {
        mappings[event]?() ?? []
    }
}
