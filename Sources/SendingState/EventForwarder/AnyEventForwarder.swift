//
//  AnyEventForwarder.swift
//  SendingState
//
//  Created by SunSoo Jeon on 03.10.2022.
//

/// A type-erased wrapper for `EventForwardable` conformers.
///
/// Enables storage of heterogeneous forwarders in collections
/// without exposing their concrete types.
///
/// Use when abstracting away specific forwarder types.
@MainActor
public struct AnyEventForwarder: EventForwardable {
    /// A closure that resolves actions for a given sender and event.
    private let _actions: (AnyObject, SenderEvent) -> [Any]

    /// A closure that returns all sender-event-action mappings.
    private let _allMappings: () -> [
        (sender: AnyObject, event: SenderEvent, actions: [Any])
    ]

    /// A closure that returns all unique senders without evaluating
    /// lazy action closures.
    private let _allSenders: () -> [AnyObject]

    /// Creates a type-erased wrapper from an `EventForwardable` conformer.
    ///
    /// - Parameter base: The `EventForwardable` conformer to wrap.
    public init<EventForwardableType: EventForwardable>(
        _ base: EventForwardableType
    ) {
        _actions = base.actions
        _allMappings = { base.allMappings }
        _allSenders = { base.allSenders }
    }

    // MARK: - EventForwardable

    public var allMappings: [
        (sender: AnyObject, event: SenderEvent, actions: [Any])
    ] {
        _allMappings()
    }

    public var allSenders: [AnyObject] { _allSenders() }

    public func actions(for sender: AnyObject, event: SenderEvent) -> [Any] {
        _actions(sender, event)
    }
}
