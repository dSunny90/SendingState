//
//  EventForwardingProvider.swift
//  SendingState
//
//  Created by SunSoo Jeon on 25.03.2021.
//

/// A protocol that declares a property for exposing an event forwarder.
///
/// Conforming types provide an `eventForwarder` that describes
/// how sender events are mapped to actions.
///
/// A common usage pattern is to call `assignActionHandler(to:)`
/// from a `SendingState` extension, passing an `ActionHandler` object
/// that listens to sender events and dispatches the associated actions.
///
/// This approach standardizes event-driven action forwarding across components,
/// promoting a declarative and consistent mapping flow.
/// By separating UI from business logic, UI components can focus solely
/// on presentation and event declaration,
/// while the actual business behavior is delegated to the action handler.
@MainActor
public protocol EventForwardingProvider: AnyObject {
    /// The event forwarder that defines sender-event-actions mappings
    var eventForwarder: EventForwardable { get }
}
