//
//  EventForwarderGroup.swift
//  SendingState
//
//  Created by SunSoo Jeon on 13.03.2021.
//

/// A type that groups multiple event forwarders into a single sendable unit.
///
/// Use `EventForwarderGroup` to combine event forwarders for unified action lookup.
/// Flattens the results of all contained forwarders when resolving actions.
public struct EventForwarderGroup<Action>: EventSendable {
    public typealias Sender = AnyObject

    public var allMappings: [
        (sender: AnyObject, event: SenderEvent, actions: [Action])
    ] {
        storage.flatMap { $0.allMappings }
    }

    private let storage: [EventForwarder<Action>]
    internal var all: [EventForwarder<Action>] { storage }

    /// Creates a group of event forwarders.
    ///
    /// - Parameter storage: An array of `EventForwarder` objects containing
    ///                      sender–event–action mappings.
    public init(_ storage: [EventForwarder<Action>]) { self.storage = storage }

    /// Returns all actions associated with the given `sender` and `event`
    /// across the group.
    ///
    /// - Parameters:
    ///   - sender: The object generating the event.
    ///   - event: The specific event triggered by the sender.
    /// - Returns: An array of actions to be executed for the event.
    public func actions(for sender: Sender, event: SenderEvent) -> [Action] {
        storage.flatMap { $0.sender === sender ? $0.actions(for: event) : [] }
    }
}
