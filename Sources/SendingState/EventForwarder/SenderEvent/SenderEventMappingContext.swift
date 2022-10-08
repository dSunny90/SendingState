//
//  SenderEventMappingContext.swift
//  SendingState
//
//  Created by SunSoo Jeon on 03.10.2022.
//

import Foundation

#if os(iOS) || targetEnvironment(macCatalyst)
import UIKit
#endif

/// A context for defining event-to-action mappings in `EventForwarder`.
///
/// Provides methods like `control(...)` and `gesture(...)`
/// within `EventForwarder`'s result builder.
///
/// ### Example:
/// ```swift
/// EventForwarder(button) { sender, ctx in
///     ctx.control([.touchUpInside]) {
///         [MyAction.buttonTapped(sender.tag)]
///     }
/// }
/// ```
///
/// The action closure is evaluated lazily at event time, allowing
/// you to capture real-time sender state (e.g., `sender.isOn`, `sender.value`).
public struct SenderEventMappingContext {
    /// The sender whose `boundState` is read at event time.
    private let senderRef: AnyObject?

    /// Creates a context without a sender reference.
    init() {
        self.senderRef = nil
    }

    /// Creates a context bound to a sender for state-aware overloads.
    init(sender: AnyObject) {
        self.senderRef = sender
    }

    /// Resolves the sender's `boundState` as the given `State` type.
    ///
    /// Called at **event time** (inside the action closure), not at setup time.
    /// Returns `nil` silently if state is unavailable — this can happen
    /// legitimately during `allMappings` evaluation before `configure` is called.
    private func resolveState<State>() -> State? {
        guard let sender = senderRef as? NSObject,
              let state = sender.boundState as? State else {
            return nil
        }
        return state
    }

    #if os(iOS) || targetEnvironment(macCatalyst)
    /// Creates a control event mapping.
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

    /// Creates a custom gesture event mapping.
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

    // MARK: - Gesture Convenience Methods

    /// Creates a tap gesture mapping.
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

    /// Creates a long press gesture mapping.
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

    /// Creates a swipe gesture mapping.
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

    /// Creates a pan gesture mapping.
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

    /// Creates a pinch gesture mapping.
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

    /// Creates a rotation gesture mapping.
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

    /// Creates a screen edge pan gesture mapping.
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

    /// Creates a hover gesture mapping (iOS 13.4+).
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

    // MARK: - State-Aware Overloads

    /// Creates a control event mapping that provides the sender's state.
    ///
    /// The state is resolved lazily at event time from the sender's `boundState`.
    /// If no state is available or the type doesn't match, actions are skipped.
    ///
    /// - Parameters:
    ///   - event: A UIControl event (e.g., `.touchUpInside`).
    ///   - actions: A closure that receives the typed state and returns actions.
    /// - Returns: A mapping from the event to an action provider closure.
    public func control<Action, State>(
        _ event: UIControl.Event,
        _ actions: @escaping (State) -> [Action]
    ) -> [SenderEvent: () -> [Action]] {
        [.control(.init(event)): {
            guard let state: State = self.resolveState() else { return [] }
            return actions(state)
        }]
    }

    /// Creates a custom gesture event mapping that provides the sender's state.
    ///
    /// - Parameters:
    ///   - event: A `SenderEvent.Gesture` defining the gesture configuration.
    ///   - actions: A closure that receives the typed state and returns actions.
    /// - Returns: A mapping from the gesture event to an action provider closure.
    public func gesture<Action, State>(
        _ event: SenderEvent.Gesture,
        _ actions: @escaping (State) -> [Action]
    ) -> [SenderEvent: () -> [Action]] {
        [.gesture(event): {
            guard let state: State = self.resolveState() else { return [] }
            return actions(state)
        }]
    }

    /// Creates a tap gesture mapping that provides the sender's state.
    ///
    /// - Parameters:
    ///   - numberOfTaps: Required tap count (default: 1).
    ///   - numberOfTouches: Required finger count (default: 1).
    ///   - states: Gesture states that trigger the actions (default: `.recognized`).
    ///   - actions: A closure that receives the typed state and returns actions.
    /// - Returns: A mapping from the tap gesture to an action provider closure.
    public func tapGesture<Action, State>(
        numberOfTaps: Int = 1,
        numberOfTouches: Int = 1,
        on states: Set<UIGestureRecognizer.State> = [.recognized],
        _ actions: @escaping (State) -> [Action]
    ) -> [SenderEvent: () -> [Action]] {
        gesture(
            .init(
                kind: .tap,
                states: states,
                numberOfTaps: numberOfTaps,
                numberOfTouches: numberOfTouches
            ),
            actions
        )
    }

    /// Creates a long press gesture mapping that provides the sender's state.
    ///
    /// - Parameters:
    ///   - minimumPressDuration: Minimum press duration in seconds (default: 0.5).
    ///   - numberOfTaps: Required tap count before press (default: 0).
    ///   - numberOfTouches: Required finger count (default: 1).
    ///   - states: Gesture states that trigger the actions (default: `.began`, `.ended`).
    ///   - actions: A closure that receives the typed state and returns actions.
    /// - Returns: A mapping from the long press gesture to an action provider closure.
    public func longPressGesture<Action, State>(
        minimumPressDuration: TimeInterval = 0.5,
        numberOfTaps: Int = 0,
        numberOfTouches: Int = 1,
        on states: Set<UIGestureRecognizer.State> = [.began, .ended],
        _ actions: @escaping (State) -> [Action]
    ) -> [SenderEvent: () -> [Action]] {
        gesture(
            .init(
                kind: .longPress,
                states: states,
                numberOfTaps: numberOfTaps,
                numberOfTouches: numberOfTouches,
                minimumPressDuration: minimumPressDuration
            ),
            actions
        )
    }

    /// Creates a swipe gesture mapping that provides the sender's state.
    ///
    /// - Parameters:
    ///   - direction: Required swipe direction (default: `.right`).
    ///   - numberOfTouches: Required finger count (default: 1).
    ///   - states: Gesture states that trigger the actions (default: `.recognized`).
    ///   - actions: A closure that receives the typed state and returns actions.
    /// - Returns: A mapping from the swipe gesture to an action provider closure.
    public func swipeGesture<Action, State>(
        direction: UISwipeGestureRecognizer.Direction = .right,
        numberOfTouches: Int = 1,
        on states: Set<UIGestureRecognizer.State> = [.recognized],
        _ actions: @escaping (State) -> [Action]
    ) -> [SenderEvent: () -> [Action]] {
        gesture(
            .init(
                kind: .swipe,
                states: states,
                numberOfTouches: numberOfTouches,
                direction: direction
            ),
            actions
        )
    }

    /// Creates a pan gesture mapping that provides the sender's state.
    ///
    /// - Parameters:
    ///   - states: Gesture states that trigger the actions (default: `.changed`, `.ended`).
    ///   - actions: A closure that receives the typed state and returns actions.
    /// - Returns: A mapping from the pan gesture to an action provider closure.
    public func panGesture<Action, State>(
        on states: Set<UIGestureRecognizer.State> = [.changed, .ended],
        _ actions: @escaping (State) -> [Action]
    ) -> [SenderEvent: () -> [Action]] {
        gesture(
            .init(
                kind: .pan,
                states: states
            ),
            actions
        )
    }

    /// Creates a pinch gesture mapping that provides the sender's state.
    ///
    /// - Parameters:
    ///   - states: Gesture states that trigger the actions (default: `.changed`, `.ended`).
    ///   - actions: A closure that receives the typed state and returns actions.
    /// - Returns: A mapping from the pinch gesture to an action provider closure.
    public func pinchGesture<Action, State>(
        on states: Set<UIGestureRecognizer.State> = [.changed, .ended],
        _ actions: @escaping (State) -> [Action]
    ) -> [SenderEvent: () -> [Action]] {
        gesture(
            .init(
                kind: .pinch,
                states: states
            ),
            actions
        )
    }

    /// Creates a rotation gesture mapping that provides the sender's state.
    ///
    /// - Parameters:
    ///   - states: Gesture states that trigger the actions (default: `.changed`, `.ended`).
    ///   - actions: A closure that receives the typed state and returns actions.
    /// - Returns: A mapping from the rotation gesture to an action provider closure.
    public func rotationGesture<Action, State>(
        on states: Set<UIGestureRecognizer.State> = [.changed, .ended],
        _ actions: @escaping (State) -> [Action]
    ) -> [SenderEvent: () -> [Action]] {
        gesture(
            .init(
                kind: .rotation,
                states: states
            ),
            actions
        )
    }

    /// Creates a screen edge pan gesture mapping that provides the sender's state.
    ///
    /// - Parameters:
    ///   - edges: Screen edges from which the gesture must begin (default: `.left`).
    ///   - states: Gesture states that trigger the actions (default: `.recognized`).
    ///   - actions: A closure that receives the typed state and returns actions.
    /// - Returns: A mapping from the screen edge gesture to an action provider closure.
    public func screenEdgeGesture<Action, State>(
        edges: UIRectEdge = .left,
        on states: Set<UIGestureRecognizer.State> = [.recognized],
        _ actions: @escaping (State) -> [Action]
    ) -> [SenderEvent: () -> [Action]] {
        gesture(
            .init(
                kind: .screenEdge,
                states: states,
                edges: edges
            ),
            actions
        )
    }

    /// Creates a hover gesture mapping that provides the sender's state (iOS 13.4+).
    ///
    /// - Parameters:
    ///   - states: Gesture states that trigger the actions (default: `.changed`).
    ///   - actions: A closure that receives the typed state and returns actions.
    /// - Returns: A mapping from the hover gesture to an action provider closure.
    @available(iOS 13.4, *)
    public func hoverGesture<Action, State>(
        on states: Set<UIGestureRecognizer.State> = [.changed],
        _ actions: @escaping (State) -> [Action]
    ) -> [SenderEvent: () -> [Action]] {
        gesture(
            .init(
                kind: .hover,
                states: states
            ),
            actions
        )
    }
    #endif
}
