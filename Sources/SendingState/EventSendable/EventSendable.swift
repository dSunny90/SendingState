//
//  EventSendable.swift
//  SendingState
//
//  Created by SunSoo Jeon on 06.03.2021.
//

/// A protocol for types that map UI events to actions and forward them.
///
/// Typically, you define `Action` as an enum listing all possible actions
/// your UI can emit. Use associated values for actions that need additional data
/// such as user input or sender information.
///
/// ### Example:
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
public protocol EventSendable {
    associatedtype Action

    /// All registered sender-event-action mappings managed by this forwarder.
    ///
    /// Use this property to enumerate sender-event relationships, such as
    /// when dynamically attaching targets or observing available events at runtime.
    var allMappings: [(sender: AnyObject, event: SenderEvent, actions: [Action])] { get }

    /// Returns the actions for a given sender and event.
    ///
    /// Retrieves the actions to forward when a sender triggers an event.
    /// Returns an empty array if no matching mapping exists.
    ///
    /// - Parameters:
    ///   - sender: The sender object that triggered the event.
    ///   - event: The event that occurred.
    /// - Returns: An array of actions to forward.
    func actions(for sender: AnyObject, event: SenderEvent) -> [Action]
}
