//
//  EventForwardable.swift
//  SendingState
//
//  Created by SunSoo Jeon on 25.03.2021.
//

/// Declares that a type can describe and forward actions when a sender and its
/// associated event are triggered.
///
/// An event forwardable type maintains a list of sender-event-actions
/// relationships, and can forward the associated actions dynamically when the
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
/// ```
///
/// **Creating Your Own Event Forwarding Structures**
///
/// Instead of implementing the `EventForwardable` protocol directly,
/// create your event forwarding structures using the `SenderGroup` type
/// provided by the SendingState framework. `SenderGroup` aggregates multiple
/// event forwarders into a unified collection.
@MainActor
public protocol EventForwardable {
    /// Returns all registered sender-event-actions mappings that managed by
    /// this forwarder.
    ///
    /// Use this property when you need to enumerate all sender-event
    /// relationships, such as when dynamically attaching targets or observing
    /// available event at runtime.
    var allMappings: [(sender: AnyObject, event: SenderEvent, actions: [Any])] { get }

    /// Returns the actions for a given sender and event.
    ///
    /// Use this method to retrieve the actions to forward when a particular
    /// sender triggers a corresponding event.
    /// If no matching mapping exists, returns an empty array.
    func actions(for sender: AnyObject, event: SenderEvent) -> [Any]
}
