//
//  EventSendingProvider.swift
//  SendingState
//
//  Created by SunSoo Jeon on 16.03.2021.
//

/// A protocol for components that forward UI events as actions.
///
/// Conforming types provide an `eventForwarder` that defines
/// how UI events map to actions.
///
/// ### Example:
/// ```swift
/// var eventForwarder: EventSendable {
///     EventForwarderGroup<MyAction>([
///         EventForwarder(sender: button, mappings: [
///             .control(.init(.touchUpInside)): { return [.didTapButton] }
///         ]),
///         EventForwarder(sender: toggle, mappings: [
///             .control(.init(.valueChanged)): { [weak self] in
///                 guard let self = self else { return [] }
///                 return [.didToggleSwitch(self.toggle.isOn)]
///             }
///         ]),
///         EventForwarder(sender: slider, mappings: [
///             .control(.init(.valueChanged)): { [weak self] in
///                 guard let self = self else { return [] }
///                 return [.didSlide(self.slider.value)]
///             }
///         ])
///     ])
/// }
/// ```
///
/// This separates UI concerns from business logic: views declare events,
/// while handlers process the corresponding actions.
public protocol EventSendingProvider: AnyObject {
    /// The event forwarder that defines event-to-action mappings.
    var eventForwarder: EventSendable { get }
}
