//
//  SenderEvent.swift
//  SendingState
//
//  Created by SunSoo Jeon on 04.03.2021.
//
#if os(iOS) || targetEnvironment(macCatalyst)
import UIKit
#endif
#if os(macOS) && !targetEnvironment(macCatalyst)
import AppKit
#endif

/// Represents a UI-triggered event such as button taps or gestures.
public enum SenderEvent: Hashable {
    #if os(iOS) || targetEnvironment(macCatalyst)
    /// A UIControl event.
    case control(Control)

    /// A UIGestureRecognizer event with its state.
    case gesture(Gesture)
    #else
    /// Placeholder for non-iOS platforms to prevent empty enum warning.
    case _unavailable
    #endif

    #if os(iOS) || targetEnvironment(macCatalyst)
    /// Wraps `UIControl.Event` to make it hashable.
    ///
    /// Enables control events (e.g., `.touchUpInside`) to be used as keys
    /// for action mappings.
    public struct Control: Hashable {
        @usableFromInline
        internal let rawValue: UIControl.Event.RawValue

        @inlinable
        public init(_ event: UIControl.Event) {
            self.rawValue = event.rawValue
        }

        @inlinable
        public var value: UIControl.Event {
            UIControl.Event(rawValue: rawValue)
        }
    }

    /// Describes a gesture recognizer event and its trigger conditions.
    ///
    /// Defines the gesture type, allowed states, and optional parameters
    /// such as tap count or swipe direction.
    public struct Gesture: Hashable {
        /// A set of gesture types that can be enabled together.
        ///
        /// Configures which gesture types to attach to a view.
        ///
        /// ### Example:
        /// ```swift
        /// [.tap, .longPress] // Enables both tap and long press gestures
        /// ```
        public struct Kind: OptionSet, Hashable {
            public let rawValue: UInt

            @inlinable
            public init(rawValue: UInt) {
                self.rawValue = rawValue
            }

            // MARK: - Common Gestures
            public static let tap           = Self(rawValue: 1 << 0)
            public static let longPress     = Self(rawValue: 1 << 1)
            public static let swipe         = Self(rawValue: 1 << 2)

            // MARK: - Continuous Gestures
            public static let pan           = Self(rawValue: 1 << 3)
            public static let pinch         = Self(rawValue: 1 << 4)
            public static let rotation      = Self(rawValue: 1 << 5)

            // MARK: - Edge / Pointer Gestures
            public static let screenEdge    = Self(rawValue: 1 << 6)

            @available(iOS 13.0, *)
            public static let hover         = Self(rawValue: 1 << 7)
        }

        public let kind: Kind
        public let states: Set<UIGestureRecognizer.State>

        // Tap-specific
        public let numberOfTaps: Int?
        public let numberOfTouches: Int?

        // Swipe-specific
        public let direction: UISwipeGestureRecognizer.Direction?

        // Long press-specific
        public let minimumPressDuration: TimeInterval?

        // Screen edge-specific
        public let edges: UIRectEdge?

        @inlinable
        internal init(kind: Kind,
                    states: Set<UIGestureRecognizer.State> = [.recognized],
                    numberOfTaps: Int? = nil,
                    numberOfTouches: Int? = nil,
                    direction: UISwipeGestureRecognizer.Direction? = nil,
                    minimumPressDuration: TimeInterval? = nil,
                    edges: UIRectEdge? = nil) {
            self.kind = kind
            self.states = states
            self.numberOfTaps = numberOfTaps
            self.numberOfTouches = numberOfTouches
            self.direction = direction
            self.minimumPressDuration = minimumPressDuration
            self.edges = edges
        }

        public static func == (lhs: Gesture, rhs: Gesture) -> Bool {
            lhs.kind == rhs.kind &&
            lhs.states == rhs.states &&
            lhs.numberOfTaps == rhs.numberOfTaps &&
            lhs.numberOfTouches == rhs.numberOfTouches &&
            lhs.direction == rhs.direction &&
            lhs.minimumPressDuration == rhs.minimumPressDuration &&
            lhs.edges == rhs.edges
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(kind)
            hasher.combine(states)
            hasher.combine(numberOfTaps)
            hasher.combine(numberOfTouches)
            hasher.combine(direction?.rawValue)
            hasher.combine(minimumPressDuration)
            hasher.combine(edges?.rawValue)
        }
    }
    #else
    #endif
}
