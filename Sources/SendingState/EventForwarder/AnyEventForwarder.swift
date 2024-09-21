//
//  AnyEventForwarder.swift
//  SendingState
//
//  Created by SunSoo Jeon on 03.10.2022.
//

/// A type-erased wrapper for any `EventForwardable` conformer.
///
/// `AnyEventForwarder` allows you to store heterogeneous forwarders in
/// collections or work with them uniformly without exposing their underlying
/// concrete types.
///
/// Use `AnyEventForwarder` when you need to abstract away the specific
/// event forwarder types.
@MainActor
public struct AnyEventForwarder: EventForwardable {
    /// A closure that resolves actions for a given sender and event.
    private let _actions: (AnyObject, SenderEvent) -> [Any]

    /// A closure that returns all sender-event-action mappings.
    private let _allMappings: () -> [
        (sender: AnyObject, event: SenderEvent, actions: [Any])
    ]

    /// Creates a type-erased event forwarder from any `EventForwardable`
    /// conformer.
    public init<EventForwardableType: EventForwardable>(
        _ base: EventForwardableType
    ) {
        _actions = base.actions
        _allMappings = { base.allMappings }
    }

    public var allMappings: [
        (sender: AnyObject, event: SenderEvent, actions: [Any])
    ] {
        _allMappings()
    }

    public func actions(for sender: AnyObject, event: SenderEvent) -> [Any] {
        _actions(sender, event)
    }
}
