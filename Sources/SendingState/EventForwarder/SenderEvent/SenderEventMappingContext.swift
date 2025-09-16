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
    ///   - event: A UIControl event (e.g., `.touchUpInside`).
    ///   - actions: A closure that returns the actions to perform.
    ///              This closure is called at event time, not at setup time.
    /// - Returns: A mapping from the event to an action provider closure.
    public func control<Action>(
        _ event: UIControl.Event,
        _ actions: @escaping () -> [Action]
    ) -> [SenderEvent: () -> [Action]] {
        [.control(.init(event)): actions]
    }

    /// Creates a gesture event mapping for a custom gesture event.
    ///
    /// - Parameters:
    ///   - event: A `SenderEvent.Gesture` defining the gesture configuration.
    ///   - actions: A closure that returns the actions to perform.
    ///              This closure is called at event time, not at setup time.
    /// - Returns: A mapping from the gesture event to an action provider closure.
    public func gesture<Action>(
        _ event: SenderEvent.Gesture,
        _ actions: @escaping () -> [Action]
    ) -> [SenderEvent: () -> [Action]] {
        [.gesture(event): actions]
    }

    // MARK: - Sugar Gesture Generators
    /// Creates a tap gesture event mapping.
    ///
    /// - Parameters:
    ///   - numberOfTaps: Required tap count (default: 1).
    ///   - numberOfTouches: Required finger count (default: 1).
    ///   - states: Gesture states that trigger the actions (default: `.recognized`).
    ///   - actions: A closure that returns the actions to perform.
    /// - Returns: A mapping from the tap gesture to an action provider closure.
    public func tapGesture<Action>(
        numberOfTaps: Int = 1,
        numberOfTouches: Int = 1,
        on states: Set<UIGestureRecognizer.State> = [.recognized],
        _ actions: @escaping () -> [Action]
    ) -> [SenderEvent: () -> [Action]] {
        [.gesture(
            .init(
                kind: .tap,
                states: states,
                numberOfTaps: numberOfTaps,
                numberOfTouches: numberOfTouches
            )
        ): actions]
    }

    /// Creates a long press gesture event mapping.
    ///
    /// - Parameters:
    ///   - minimumPressDuration: Minimum press duration in seconds (default: 0.5).
    ///   - numberOfTaps: Required tap count before press (default: 0).
    ///   - numberOfTouches: Required finger count (default: 1).
    ///   - states: Gesture states that trigger the actions (default: `.began`, `.ended`).
    ///   - actions: A closure that returns the actions to perform.
    /// - Returns: A mapping from the long press gesture to an action provider closure.
    public func longPressGesture<Action>(
        minimumPressDuration: TimeInterval = 0.5,
        numberOfTaps: Int = 0,
        numberOfTouches: Int = 1,
        on states: Set<UIGestureRecognizer.State> = [.began, .ended],
        _ actions: @escaping () -> [Action]
    ) -> [SenderEvent: () -> [Action]] {
        [.gesture(
            .init(
                kind: .longPress,
                states: states,
                numberOfTaps: numberOfTaps,
                numberOfTouches: numberOfTouches,
                minimumPressDuration: minimumPressDuration
            )
        ): actions]
    }

    /// Creates a swipe gesture event mapping.
    ///
    /// - Parameters:
    ///   - direction: Required swipe direction (default: `.right`).
    ///   - numberOfTouches: Required finger count (default: 1).
    ///   - states: Gesture states that trigger the actions (default: `.recognized`).
    ///   - actions: A closure that returns the actions to perform.
    /// - Returns: A mapping from the swipe gesture to an action provider closure.
    public func swipeGesture<Action>(
        direction: UISwipeGestureRecognizer.Direction = .right,
        numberOfTouches: Int = 1,
        on states: Set<UIGestureRecognizer.State> = [.recognized],
        _ actions: @escaping () -> [Action]
    ) -> [SenderEvent: () -> [Action]] {
        [.gesture(
            .init(
                kind: .swipe,
                states: states,
                numberOfTouches: numberOfTouches,
                direction: direction
            )
        ): actions]
    }

    /// Creates a pan gesture event mapping.
    ///
    /// - Parameters:
    ///   - states: Gesture states that trigger the actions (default: `.changed`, `.ended`).
    ///   - actions: A closure that returns the actions to perform.
    /// - Returns: A mapping from the pan gesture to an action provider closure.
    public func panGesture<Action>(
        on states: Set<UIGestureRecognizer.State> = [.changed, .ended],
        _ actions: @escaping () -> [Action]
    ) -> [SenderEvent: () -> [Action]] {
        [.gesture(
            .init(
                kind: .pan,
                states: states
            )
        ): actions]
    }

    /// Creates a pinch gesture event mapping.
    ///
    /// - Parameters:
    ///   - states: Gesture states that trigger the actions (default: `.changed`, `.ended`).
    ///   - actions: A closure that returns the actions to perform.
    /// - Returns: A mapping from the pinch gesture to an action provider closure.
    public func pinchGesture<Action>(
        on states: Set<UIGestureRecognizer.State> = [.changed, .ended],
        _ actions: @escaping () -> [Action]
    ) -> [SenderEvent: () -> [Action]] {
        [.gesture(
            .init(
                kind: .pinch,
                states: states
            )
        ): actions]
    }

    /// Creates a rotation gesture event mapping.
    ///
    /// - Parameters:
    ///   - states: Gesture states that trigger the actions (default: `.changed`, `.ended`).
    ///   - actions: A closure that returns the actions to perform.
    /// - Returns: A mapping from the rotation gesture to an action provider closure.
    public func rotationGesture<Action>(
        on states: Set<UIGestureRecognizer.State> = [.changed, .ended],
        _ actions: @escaping () -> [Action]
    ) -> [SenderEvent: () -> [Action]] {
        [.gesture(
            .init(
                kind: .rotation,
                states: states
            )
        ): actions]
    }

    /// Creates a screen edge pan gesture event mapping.
    ///
    /// - Parameters:
    ///   - edges: Screen edges from which the gesture must begin (default: `.left`).
    ///   - states: Gesture states that trigger the actions (default: `.recognized`).
    ///   - actions: A closure that returns the actions to perform.
    /// - Returns: A mapping from the screen edge gesture to an action provider closure.
    public func screenEdgeGesture<Action>(
        edges: UIRectEdge = .left,
        on states: Set<UIGestureRecognizer.State> = [.recognized],
        _ actions: @escaping () -> [Action]
    ) -> [SenderEvent: () -> [Action]] {
        [.gesture(
            .init(
                kind: .screenEdge,
                states: states,
                edges: edges
            )
        ): actions]
    }

    /// Creates a hover gesture event mapping (iPadOS/macCatalyst only).
    ///
    /// - Parameters:
    ///   - states: Gesture states that trigger the actions (default: `.changed`).
    ///   - actions: A closure that returns the actions to perform.
    /// - Returns: A mapping from the hover gesture to an action provider closure.
    @available(iOS 13.4, *)
    public func hoverGesture<Action>(
        on states: Set<UIGestureRecognizer.State> = [.changed],
        _ actions: @escaping () -> [Action]
    ) -> [SenderEvent: () -> [Action]] {
        [.gesture(
            .init(
                kind: .hover,
                states: states
            )
        ): actions]
    }
    #endif
}
