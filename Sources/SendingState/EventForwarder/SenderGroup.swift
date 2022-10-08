//
//  SenderGroup.swift
//  SendingState
//
//  Created by SunSoo Jeon on 13.03.2021.
//

// MARK: - History
// - Oct 2022: Renamed `EventForwarderGroup` to `SenderGroup`.
//
//   It remains an `EventForwardable` implementation, but was updated to match
//   the non-generic action model. Like `EventForwarder`, `actions(for:)`
//   now returns `[Any]`. The mapping API was also moved to `@resultBuilder`
//   for a more concise, readable configuration style.

/// A type that groups multiple event forwarders into a single forwardable unit.
///
/// Use `SenderGroup` to combine event forwarders for unified action lookup.
/// Flattens the results of all contained forwarders when resolving actions.
public struct SenderGroup: EventForwardable {
    /// The collection of event forwarders contained in this group.
    private let forwarders: [EventForwardable]

    /// Creates a group of event forwarders.
    ///
    /// - Parameter content: A closure that defines the forwarders to group.
    public init(@EventForwarderBuilder _ content: () -> [EventForwardable]) {
        self.forwarders = content()
    }

    public var allMappings: [
        (sender: AnyObject, event: SenderEvent, actions: [Any])
    ] {
        forwarders.flatMap { $0.allMappings }
    }

    public var allSenders: [AnyObject] { forwarders.flatMap { $0.allSenders } }

    public func actions(for sender: AnyObject, event: SenderEvent) -> [Any] {
        forwarders.flatMap { $0.actions(for: sender, event: event) }
    }
}

// MARK: - Result Builders
/// A result builder that constructs event forwarders.
///
/// Use `EventForwarderBuilder` to declare multiple event forwarders
/// within a single closure.
///
/// ### Example 1: Multiple senders
/// ```swift
/// SenderGroup {
///     EventForwarder(button) { ... }
///     EventForwarder(slider) { ... }
///     EventForwarder(view) { ... }
/// }
/// ```
///
/// ### Example 2: Mixed forwarder types
/// ```swift
/// MyCustomEventForwardable {
///     EventForwarder(button) { ... }
///     MyCustomEventForwarder()
/// }
/// ```
@resultBuilder public enum EventForwarderBuilder {
    /// Combines multiple event forwarders into an array.
    ///
    /// Typically not called directly. Instead, declare multiple forwarders
    /// within a closure, and the builder collects them into an array.
    ///
    /// - Parameter components: The individual forwarders to combine.
    /// - Returns: An array of type-erased event forwarders.
    public static func buildBlock(
        _ components: EventForwardable...
    ) -> [AnyEventForwarder] {
        components.map { AnyEventForwarder($0) }
    }
}
