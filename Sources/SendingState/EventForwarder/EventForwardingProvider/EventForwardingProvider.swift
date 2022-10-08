//
//  EventForwardingProvider.swift
//  SendingState
//
//  Created by SunSoo Jeon on 16.03.2021.
//

// MARK: - History
// - Oct 2022: Renamed `EventSendingProvider` to `EventForwardingProvider`
//   to match the `EventSendable` -> `EventForwardable` rename.

/// A protocol for components that forward UI events as actions.
///
/// Conforming types provide an `eventForwarder` that defines
/// how UI events map to actions.
///
/// Typically adopted by views or UI components. Call `addActionHandler(to:)`
/// to connect the forwarder to an `ActionHandlingProvider` that handles
/// the dispatched actions.
///
/// This separates UI concerns from business logic: views declare events,
/// while handlers process the corresponding actions.
public protocol EventForwardingProvider: AnyObject {
    /// The event forwarder that defines event-to-action mappings.
    var eventForwarder: EventForwardable { get }
}
