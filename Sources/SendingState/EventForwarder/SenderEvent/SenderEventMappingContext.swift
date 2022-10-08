//
//  SenderEventMappingContext.swift
//  SendingState
//
//  Created by SunSoo Jeon on 03.10.2022.
//

#if os(iOS) || targetEnvironment(macCatalyst)
import UIKit
#endif
/// A context passed to the EventForwarder for defining event-action mappings.
///
/// Used within the result builder block of `EventForwarder`,
/// allowing users to call `.control(...)`, `.gesture(...)`, etc.
///
/// - Example:
/// ```swift
/// EventForwarder(button) { sender, ctx in
///     ctx.control([.touchUpInside]) {
///         [MyAction.buttonTapped(sender.tag)]
///     }
/// }
/// ```
public struct SenderEventMappingContext {
    #if os(iOS) || targetEnvironment(macCatalyst)
    /// Creates a control event mapping for the given control events.
    ///
    /// - Parameters:
    ///   - events: A set of UIControl events (e.g., [.touchUpInside]).
    ///   - actions: A closure that returns an array of action values.ㄴ도
    /// - Returns: A mapping from SenderEvent to Action array.
    public func control<Action>(
        _ event: UIControl.Event,
        _ actions: @escaping () -> [Action]
    ) -> [SenderEvent: [Action]] {
        [.control(.init(event)): actions()]
    }

    /// Creates a gesture event mapping for a custom gesture event.
    ///
    /// - Parameters:
    ///   - event: A `SenderEvent.Gesture` representing gesture type/state.
    ///   - actions: A closure that returns an array of action values.
    /// - Returns: A mapping from SenderEvent to Action array.
    public func gesture<Action>(
        _ event: SenderEvent.Gesture,
        _ actions: @escaping () -> [Action]
    ) -> [SenderEvent: [Action]] {
        [.gesture(event): actions()]
    }

    // MARK: - Sugar Gesture Generators
    /// Creates a tap gesture event mapping.
    ///
    /// - Parameters:
    ///   - numberOfTaps: Number of taps required to trigger the gesture.
    ///   - numberOfTouches: Number of fingers required for the gesture.
    ///   - states: Recognized gesture states to respond to.
    ///   - actions: Closure returning the actions to perform.
    /// - Returns: Mapping from `SenderEvent.gesture` to corresponding actions.
    public func tapGesture<Action>(
        numberOfTaps: Int = 1,
        numberOfTouches: Int = 1,
        on states: Set<UIGestureRecognizer.State> = [.recognized],
        _ actions: @escaping () -> [Action]
    ) -> [SenderEvent: [Action]] {
        [.gesture(
            .init(
                kind: .tap,
                states: states,
                numberOfTaps: numberOfTaps,
                numberOfTouches: numberOfTouches
            )
        ): actions()]
    }

    /// Creates a long press gesture event mapping.
    ///
    /// - Parameters:
    ///   - minimumPressDuration: Minimum press duration in seconds.
    ///   - numberOfTaps: Number of taps required to trigger the gesture.
    ///   - numberOfTouches: Number of fingers required for the gesture.
    ///   - states: Recognized gesture states to respond to.
    ///   - actions: Closure returning the actions to perform.
    /// - Returns: Mapping from `SenderEvent.gesture` to corresponding actions.
    public func longPressGesture<Action>(
        minimumPressDuration: TimeInterval = 0.5,
        numberOfTaps: Int = 0,
        numberOfTouches: Int = 1,
        on states: Set<UIGestureRecognizer.State> = [.began, .ended],
        _ actions: @escaping () -> [Action]
    ) -> [SenderEvent: [Action]] {
        [.gesture(
            .init(
                kind: .longPress,
                states: states,
                numberOfTaps: numberOfTaps,
                numberOfTouches: numberOfTouches,
                minimumPressDuration: minimumPressDuration
            )
        ): actions()]
    }

    /// Creates a swipe gesture event mapping.
    ///
    /// - Parameters:
    ///   - direction: The direction in which the swipe must occur.
    ///   - numberOfTouches: Number of fingers required for the gesture.
    ///   - states: Recognized gesture states to respond to.
    ///   - actions: Closure returning the actions to perform.
    /// - Returns: Mapping from `SenderEvent.gesture` to corresponding actions.
    public func swipeGesture<Action>(
        direction: UISwipeGestureRecognizer.Direction = .right,
        numberOfTouches: Int = 1,
        on states: Set<UIGestureRecognizer.State> = [.recognized],
        _ actions: @escaping () -> [Action]
    ) -> [SenderEvent: [Action]] {
        [.gesture(
            .init(
                kind: .swipe,
                states: states,
                numberOfTouches: numberOfTouches,
                direction: direction
            )
        ): actions()]
    }

    /// Creates a pan gesture event mapping.
    ///
    /// - Parameters:
    ///   - states: Recognized gesture states to respond to.
    ///   - actions: Closure returning the actions to perform.
    /// - Returns: Mapping from `SenderEvent.gesture` to corresponding actions.
    public func panGesture<Action>(
        on states: Set<UIGestureRecognizer.State> = [.changed, .ended],
        _ actions: @escaping () -> [Action]
    ) -> [SenderEvent: [Action]] {
        [.gesture(
            .init(
                kind: .pan,
                states: states
            )
        ): actions()]
    }

    /// Creates a pinch gesture event mapping.
    ///
    /// - Parameters:
    ///   - states: Recognized gesture states to respond to.
    ///   - actions: Closure returning the actions to perform.
    /// - Returns: Mapping from `SenderEvent.gesture` to corresponding actions.
    public func pinchGesture<Action>(
        on states: Set<UIGestureRecognizer.State> = [.changed, .ended],
        _ actions: @escaping () -> [Action]
    ) -> [SenderEvent: [Action]] {
        [.gesture(
            .init(
                kind: .pinch,
                states: states
            )
        ): actions()]
    }

    /// Creates a rotation gesture event mapping.
    ///
    /// - Parameters:
    ///   - states: Recognized gesture states to respond to.
    ///   - actions: Closure returning the actions to perform.
    /// - Returns: Mapping from `SenderEvent.gesture` to corresponding actions.
    public func rotationGesture<Action>(
        on states: Set<UIGestureRecognizer.State> = [.changed, .ended],
        _ actions: @escaping () -> [Action]
    ) -> [SenderEvent: [Action]] {
        [.gesture(
            .init(
                kind: .rotation,
                states: states
            )
        ): actions()]
    }

    /// Creates a screen edge pan gesture event mapping.
    ///
    /// - Parameters:
    ///   - edges: The screen edges from which the gesture must begin.
    ///   - states: Recognized gesture states to respond to.
    ///   - actions: Closure returning the actions to perform.
    /// - Returns: Mapping from `SenderEvent.gesture` to corresponding actions.
    public func screenEdgeGesture<Action>(
        edges: UIRectEdge = .left,
        on states: Set<UIGestureRecognizer.State> = [.recognized],
        _ actions: @escaping () -> [Action]
    ) -> [SenderEvent: [Action]] {
        [.gesture(
            .init(
                kind: .screenEdge,
                states: states,
                edges: edges
            )
        ): actions()]
    }

    /// Creates a hover gesture event mapping (iPadOS/macCatalyst only).
    ///
    /// - Parameters:
    ///   - states: Recognized gesture states to respond to.
    ///   - actions: Closure returning the actions to perform.
    /// - Returns: Mapping from `SenderEvent.gesture` to corresponding actions.
    @available(iOS 13.4, *)
    public func hoverGesture<Action>(
        on states: Set<UIGestureRecognizer.State> = [.changed],
        _ actions: @escaping () -> [Action]
    ) -> [SenderEvent: [Action]] {
        [.gesture(
            .init(
                kind: .hover,
                states: states
            )
        ): actions()]
    }
    #endif
}
