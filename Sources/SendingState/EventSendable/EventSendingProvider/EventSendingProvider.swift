//
//  EventSendingProvider.swift
//  SendingState
//
//  Created by SunSoo Jeon on 25.03.2021.
//

/// A protocol for declaring an event forwarder by conforming to `EventSendable`.
///
/// Conforming types provide an `eventForwarder` that describes
/// how sender events are mapped to actions.
///
/// For example:
/// ```swift
/// var eventForwarder: EventForwarderGroup<MyAction> {
///     EventForwarder {
///         EventForwarderItem(aButton as AnyObject) {
///             control(.init(.touchUpInside)) { [MyAction.didTapButton] }
///             gesture(.init(kind: .tap)) { [MyAction.singleTap] }
///         }
///         EventForwarderItem(bSlider as AnyObject) {
///             control(.init(.valueChanged)) { [MyAction.didSlide] }
///         }
///     }.eraseToEventForwarderGroup()
/// }
/// ```
///
/// This approach standardizes event-driven action sending across components,
/// promoting a declarative and consistent mapping flow.
/// By separating UI from business logic, UI components can focus solely
/// on presentation and event declaration,
/// while the actual business behavior is delegated to the action handler.
public protocol EventSendingProvider: AnyObject {
    /// The event forwarder that defines sender-event-actions mappings
    var eventForwarder: EventSendable { get }
}
