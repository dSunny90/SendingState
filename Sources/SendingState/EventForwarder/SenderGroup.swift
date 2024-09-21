//
//  SenderGroup.swift
//  SendingState
//
//  Created by SunSoo Jeon on 03.10.2022.
//

/// A type that groups multiple event forwarders into a single forwardable unit.
///
/// Use `SenderGroup` to combine several event forwarders so they can be queried
/// together for matching sender-event-actions mappings.
///
/// `SenderGroup` flattens the results of all contained forwarders when
/// resolving actions.
@MainActor
public struct SenderGroup: EventForwardable {
    /// The collection of event forwarders contained in this group.
    private let forwarders: [EventForwardable]

    /// Creates a group of event forwarders from a closure.
    ///
    /// Use `SenderGroup` to collect multiple forwarders into a single structure.
    public init(@EventForwarderBuilder _ content: () -> [EventForwardable]) {
        self.forwarders = content()
    }

    public var allMappings: [
        (sender: AnyObject, event: SenderEvent, actions: [Any])
    ] {
        forwarders.flatMap { $0.allMappings }
    }

    public func actions(for sender: AnyObject, event: SenderEvent) -> [Any] {
        forwarders.flatMap { $0.actions(for: sender, event: event) }
    }
}

// MARK: - Result Builders
/// A custom parameter attribute that builds event forwarders from closures.
///
/// You typically use `EventForwarderBuilder` as a parameter attribute for
/// closure parameters that produce one or more event forwarders, allowing
/// those closures to provide multiple sender-actions mappings.
///
/// ### Example 1:
/// ```swift
/// SenderGroup {
///     EventForwarder(button) { ... }
///     EventForwarder(slider) { ... }
///     EventForwarder(view) { ... }
/// }
/// ```
/// ### Example 2:
/// ```swift
/// MyCustomEventForwardable { // your own EventForwardable
///     EventForwarder(button) { ... }
///     MyCustomEventForwarder() // your own EventForwardable
/// }
/// ```
///
/// Clients can declare several event forwarders in a single group by using
/// multiple-statement closures, enabling structured event mapping.
@MainActor @resultBuilder public enum EventForwarderBuilder {
    /// Passes a collection of event forwarders written as child elements
    /// through unmodified.
    ///
    /// You typically don't call this method directly.
    /// Instead, you write multiple forwarder declarations inside a closure,
    /// and the builder collects them into a group.
    public static func buildBlock(
        _ components: EventForwardable...
    ) -> [AnyEventForwarder] {
        components.map { AnyEventForwarder($0) }
    }
}
