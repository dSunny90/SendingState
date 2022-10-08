//
//  EventForwarder.swift
//  SendingState
//
//  Created by SunSoo Jeon on 15.05.2021.
//

/// A type that associates a specific sender with event-actions mappings.
///
/// `EventForwarder` captures a sender instance and defines a set of mappings
/// between sender events and the actions to forward when those events occur.
///
/// Use `EventForwarder` when you want to define event behavior for an
/// individual sender.
public struct EventForwarder<Sender: AnyObject>: EventForwardable {
    /// The sender associated with this forwarder.
    private let senderRef: Sender

    /// The mappings from sender events to their corresponding actions.
    private let mappings: [SenderEvent: [Any]]

    /// Creates an event forwarder for a specific sender and its event-actions
    /// mappings.
    public init<Action>(
        _ sender: Sender,
        @SenderEventMappingBuilder<Action>
        _ content: (Sender, SenderEventMappingContext) -> [SenderEvent: [Action]]
    ) {
        senderRef = sender
        let ctx = SenderEventMappingContext()
        mappings = content(sender, ctx).mapValues { $0.map { $0 as Any } }
    }

    public var allMappings: [
        (sender: AnyObject, event: SenderEvent, actions: [Any])
    ] {
        mappings.map { (sender: senderRef, event: $0.key, actions: $0.value) }
    }

    public func actions(for sender: AnyObject, event: SenderEvent) -> [Any] {
        guard sender === senderRef else { return [] }
        return mappings[event] ?? []
    }
}

/// A custom parameter attribute that builds sender-event-to-action mappings
/// from closures.
///
///
/// You typically use `SenderEventMappingBuilder` to define multiple
/// event-to-action mappings for a single sender, allowing you to group UI
/// events — including control events, gesture recognizer events, delegate
/// callbacks, and other interaction events — within a closure.
///
/// For example:
/// ```swift
/// EventForwarder(button) { sender in
///     control(.touchUpInside) { [Action.tap] }
///     gesture(.doubleTapDidEnd) { [Action.doubleTap] }
/// }
/// ```
@resultBuilder public enum SenderEventMappingBuilder<Action> {
    /// Passes a collection of event-actions mappings written as child elements
    /// through unmodified.
    ///
    /// You typically don't call this method directly.
    /// Instead, you define multiple event-actions mappings inside a closure,
    /// and the builder collects them into a single mapping dictionary.
    public static func buildBlock(
        _ components: [SenderEvent: [Action]]...
    ) -> [SenderEvent: [Action]] {
        components.reduce(into: [:]) { result, dic in
            for (key, value) in dic {
                result[key, default: []] += value
            }
        }
    }
}
