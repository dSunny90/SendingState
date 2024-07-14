//
//  EventForwarder.swift
//  SendingState
//
//  Created by SunSoo Jeon on 13.03.2021.
//

// MARK: - History
// - Oct 2022: Refined `EventForwarder` to match the new `EventForwardable` shape.
//
//   `EventForwarder` became a sender-generic implementation, and its initializers
//   now carry the action type. `actions(for:)` was updated to map 1:1 to
//   the given sender and return the mapped actions as `[Any]`. This is
//   a trade-off of making `EventForwardable` non-generic over actions,
//   but it keeps the API much easier to adopt at call sites.
//   Also, I reworked the configuration API with `@resultBuilder`. It makes
//   mappings more readable and reduces boilerplate.

/// A type that maps events from a specific sender to actions.
///
/// `EventForwarder` captures a sender and defines mappings from its events
/// to the actions forwarded when those events occur.
///
/// Use `EventForwarder` to define event behavior for a specific sender.
@MainActor
public struct EventForwarder<Sender: AnyObject>: EventForwardable {
    /// The sender associated with this forwarder.
    @usableFromInline
    internal let senderRef: Sender

    /// The mappings from sender events to their corresponding action providers.
    /// Closures are stored to enable lazy evaluation at event time,
    /// allowing actions to capture real-time sender state.
    private let mappings: [SenderEvent: () -> [Any]]

    /// Creates an event forwarder for a specific sender with event-to-action
    /// mappings.
    ///
    /// - Parameters:
    ///   - sender: The sender whose events to forward.
    ///   - content: A closure that defines the event-to-action mappings.
    public init<Action>(
        _ sender: Sender,
        @SenderEventMappingBuilder<Action>
        _ content: (Sender, SenderEventMappingContext) -> [SenderEvent: () -> [Action]]
    ) {
        senderRef = sender
        let ctx = SenderEventMappingContext(sender: sender)
        mappings = content(sender, ctx).mapValues { actionProvider in
            { actionProvider().map { $0 as Any } }
        }
    }

    // MARK: - EventForwardable

    public var allMappings: [
        (sender: AnyObject, event: SenderEvent, actions: [Any])
    ] {
        mappings.map { (sender: senderRef, event: $0.key, actions: $0.value()) }
    }

    @inlinable
    public var allSenders: [AnyObject] { [senderRef] }

    public func actions(for sender: AnyObject, event: SenderEvent) -> [Any] {
        guard sender === senderRef else { return [] }
        return mappings[event]?() ?? []
    }
}

/// A result builder that constructs event-to-action mappings.
///
/// Use `SenderEventMappingBuilder` to define multiple event-to-action mappings
/// for a single sender, grouping UI events (control events, gesture recognizer
/// events, delegate callbacks, and other interactions) within a closure.
///
/// ### Example:
/// ```swift
/// EventForwarder(button) { sender, ctx in
///     ctx.control(.touchUpInside) { [Action.tap] }
///     ctx.gesture(.doubleTapDidEnd) { [Action.doubleTap] }
/// }
/// ```
@MainActor @resultBuilder public enum SenderEventMappingBuilder<Action> {
    /// Combines multiple event-to-action mappings into a single dictionary.
    ///
    /// Typically not called directly. Instead, define multiple mappings
    /// inside a closure, and the builder merges them into a single dictionary.
    ///
    /// - Parameter components: The individual mapping dictionaries to combine.
    /// - Returns: A merged dictionary of all event-to-action mappings.
    public static func buildBlock(
        _ components: [SenderEvent: () -> [Action]]...
    ) -> [SenderEvent: () -> [Action]] {
        components.reduce(into: [:]) { result, dic in
            for (key, newProvider) in dic {
                if let existingProvider = result[key] {
                    // Combine multiple action providers for the same event
                    result[key] = { existingProvider() + newProvider() }
                } else {
                    result[key] = newProvider
                }
            }
        }
    }
}
