//
//  SenderEvent.swift
//  SendingState
//
//  Created by SunSoo Jeon on 25.03.2021.
//
#if os(iOS) || targetEnvironment(macCatalyst)
import UIKit
#endif
#if os(macOS) && !targetEnvironment(macCatalyst)
import AppKit
#endif

/// Represents a UI-triggered event. (like button taps or gestures)
public enum SenderEvent: Hashable {
    #if os(iOS) || targetEnvironment(macCatalyst)
    /// UIControl.Event
    case control(Control)
    ///  UIGestureRecognizer event and its State
    case gesture(Gesture)
    #endif
    #if os(macOS) && !targetEnvironment(macCatalyst)
    #endif

    #if os(iOS) || targetEnvironment(macCatalyst)
    /// Wraps a `UIControl.Event` to make it `Hashable`.
    ///
    /// Enables control events (e.g. `.touchUpInside`) to be used as keys
    /// in action mapping systems.
    public struct Control: Hashable {
        private let rawValue: UIControl.Event.RawValue

        public init(_ event: UIControl.Event) {
            self.rawValue = event.rawValue
        }

        public var value: UIControl.Event {
            UIControl.Event(rawValue: rawValue)
        }
    }

    /// Describes a gesture recognizer event and its trigger conditions.
    ///
    /// Contains gesture type (e.g. tap, swipe), allowed states, and
    /// optional parameters (e.g. number of taps, direction).
    public struct Gesture: Hashable {
        /// Represents a set of gesture types that can be enabled together.
        ///
        /// Used to configure which gesture types to attach to a view.
        ///
        /// Example:
        ///     [.tap, .longPress] enables both tap and long press gestures.
        public struct Kind: OptionSet, Hashable {
            public let rawValue: UInt

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

        // tap-specific
        public let numberOfTaps: Int?
        public let numberOfTouches: Int?

        // swipe-specific
        public let direction: UISwipeGestureRecognizer.Direction?

        // longPress-specific
        public let minimumPressDuration: TimeInterval?

        // screenEdge-specific
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
    #endif
    #if os(macOS) && !targetEnvironment(macCatalyst)
    #endif
}
