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
/// var eventForwarder: EventSendable {
///     EventForwarderGroup([
///         EventForwarder(sender: button, mapping: [
///             .control(.init(.touchUpInside)): [MyAction.didTapButton]
///         ]),
///         EventForwarder(sender: toggle, mapping: [
///             .control(.init(.valueChanged)): [.didToggleSwitch(toggle.isOn)]
///         ]),
///         EventForwarder(sender: slider, mapping: [
///             .control(.init(.valueChanged)): [.didSlide(slider.value)]
///         ])
///     ])
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
