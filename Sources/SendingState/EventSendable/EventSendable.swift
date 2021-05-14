//
//  EventSendable.swift
//  SendingState
//
//  Created by SunSoo Jeon on 25.03.2021.
//

/// Declares that a type can describe and send actions when a sender and its
/// associated event are triggered.
///
/// An event sendable type maintains a list of sender-event-actions
/// relationships, and can send the associated actions dynamically when the
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
/// 
/// ```
///
public protocol EventSendable {
    associatedtype Action
    func actions(for sender: AnyObject, event: SenderEvent) -> [Action]
}
