//
//  EventSendable.swift
//  SendingState
//
//  Created by SunSoo Jeon on 25.03.2021.
//

/// Declares that a type can describe and send actions when a sender and its
/// associated event are triggered.
///
/// An event sendable type maintains a list of sender-event-actions
/// relationships, and can send the associated actions dynamically when the
/// corresponding event on a sender occurs.
///
/// You typically define `Action` as an `enum`, listing all possible actions
/// your UI can emit. If additional data, such as a `String`, `Int`, or sender
/// information, needs to accompany an action, use associated values in your
/// `enum` cases.
///
/// For example:
/// ```swift
/// enum MyAction {
///     case applyMyFilter
///     case sendReactingLog(String)
///     case sendClickLog(String)
///     case textInputChanged(String)
///     case sliderValueChanged(Float)
/// }
/// 
/// ```
///
public protocol EventSendable {
    associatedtype Action
    func actions(for sender: AnyObject, event: SenderEvent) -> [Action]
}

/// A type that links a specific sender object to a set of actions triggered
/// by certain events.
///
/// `EventForwarder` holds a mapping between `SenderEvent` values and
/// the corresponding `Action` values that should be executed
/// when that event occurs.
/// It acts as a simple lookup table for determining which actions to invoke
/// for a given event from a given sender.
///
/// - Parameters:
///   - sender: The object that generates events
///   - mapping: A dictionary mapping each `SenderEvent` to associated actions.
public struct EventForwarder<Action> {
    public let sender: AnyObject
    public let mapping: [SenderEvent: [Action]]

    /// Returns the actions mapped to the given event.
    public func actions(for event: SenderEvent) -> [Action] {
        mapping[event] ?? []
    }
}

/// A collection of `EventForwarder` instances that can be queried as a group.
///
/// `EventForwarderGroup` conforms to `EventSendable` and allows looking up
/// actions for a given sender and event across multiple forwarders.
/// This is useful when a single view or controller manages multiple
/// event-to-action mappings, and you want to resolve them in a unified way.
///
/// - Note: The `sender` match uses identity comparison (`===`) to ensure
///         that the mapping only applies to the exact object instance.
///
/// - Parameters:
///   - storage: An array of `EventForwarder` objects containing
///   sender–event–action mappings.
public struct EventForwarderGroup<Action>: EventSendable {
    public typealias Sender = AnyObject

    private let storage: [EventForwarder<Action>]
    internal var all: [EventForwarder<Action>] { storage }

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
