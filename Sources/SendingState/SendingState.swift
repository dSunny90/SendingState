//
//  SendingState.swift
//  SendingState
//
//  Created by SunSoo Jeon on 23.11.2020.
//

public struct SendingState<Base> {
    public let base: Base
    public init(_ base: Base) { self.base = base }
}

public protocol SendingStateHost {}
extension SendingStateHost {
    public var ss: SendingState<Self> { SendingState(self) }
    public static var ss: SendingState<Self>.Type { SendingState<Self>.self }
}

#if os(iOS) || targetEnvironment(macCatalyst)
import UIKit

extension UIView: SendingStateHost {}
#endif

fileprivate typealias ActionHandlerBlock =
    (_ sender: AnyObject, _ event: SenderEvent) -> (_ sender: AnyObject) -> Void

extension SendingState where Base: Configurable {
    /// Sugar for `configurer(self, input)`
    public func configure<T>(_ input: T) where T == Base.Input {
        base.configurer(base, input)
    }
}

#if os(iOS) || targetEnvironment(macCatalyst)
extension SendingState where Base: UIView & EventForwardingProvider {
    @MainActor
    public func assignActionHandler<Provider: ActionHandlingProvider>(
        to provider: Provider
    ) {
        assignEventHandlers { sender, event in
            { [weak base, weak sender, weak provider] _ in
                guard let base, let sender, let provider else { return }
                let actions = base.eventForwarder.actions(for: sender,
                                                          event: event)
                for case let action as Provider.Action in actions {
                    provider.handle(action: action)
                }
            }
        }
    }
    @MainActor
    public func assignAnyActionHandler(to provider: AnyActionHandlingProvider) {
        assignEventHandlers { sender, event in
            { [weak base, weak sender, weak provider] _ in
                guard let base, let sender, let provider else { return }
                let actions = base.eventForwarder.actions(for: sender,
                                                          event: event)
                for action in actions {
                    provider.handle(action: action)
                }
            }
        }
    }

    /// Shared logic to assign handlers to gesture/control events.
    @MainActor
    private func assignEventHandlers(
        using handlerBlock: @escaping ActionHandlerBlock
    ) {
        for (sender, event, _) in base.eventForwarder.allMappings {
            let handler = handlerBlock(sender, event)
            switch event {
            case .gesture(let gesture):
                (sender as? UIView)?
                    .ss.addGestureHandler(for: gesture, handler)

            case .control(let controlEvent):
                (sender as? UIControl)?
                    .ss.addControlEventHandler(
                        for: controlEvent.value.rawValue,
                        handler
                    )
            }
        }
    }
}

extension SendingState where Base: UIView {
    @MainActor
    fileprivate func addGestureHandler(
        for gestureEvent: SenderEvent.Gesture,
        _ handler: @escaping (_ gesture: UIGestureRecognizer) -> Void
    ) {
        if gestureEvent.kind.contains(.tap) {
            let recognizer = UITapGestureRecognizer()
            if let taps = gestureEvent.numberOfTaps {
                recognizer.numberOfTapsRequired = taps
            }
            if let touches = gestureEvent.numberOfTouches {
                recognizer.numberOfTouchesRequired = touches
            }
            attach(recognizer, on: gestureEvent.states, handler)
        }
        if gestureEvent.kind.contains(.longPress) {
            let recognizer = UILongPressGestureRecognizer()
            if let duration = gestureEvent.minimumPressDuration {
                recognizer.minimumPressDuration = duration
            }
            if let taps = gestureEvent.numberOfTaps {
                recognizer.numberOfTapsRequired = taps
            }
            if let touches = gestureEvent.numberOfTouches {
                recognizer.numberOfTouchesRequired = touches
            }
            attach(recognizer, on: gestureEvent.states, handler)
        }
        if gestureEvent.kind.contains(.swipe) {
            let recognizer = UISwipeGestureRecognizer()
            if let direction = gestureEvent.direction {
                recognizer.direction = direction
            }
            if let touches = gestureEvent.numberOfTouches {
                recognizer.numberOfTouchesRequired = touches
            }
            attach(recognizer, on: gestureEvent.states, handler)
        }
        if gestureEvent.kind.contains(.pan) {
            let recognizer = UIPanGestureRecognizer()
            if let touches = gestureEvent.numberOfTouches {
                recognizer.minimumNumberOfTouches = touches
            }
            attach(recognizer, on: gestureEvent.states, handler)
        }
        if gestureEvent.kind.contains(.pinch) {
            let recognizer = UIPinchGestureRecognizer()
            attach(recognizer, on: gestureEvent.states, handler)
        }
        if gestureEvent.kind.contains(.rotation) {
            let recognizer = UIRotationGestureRecognizer()
            attach(recognizer, on: gestureEvent.states, handler)
        }
        if gestureEvent.kind.contains(.screenEdge) {
            let recognizer = UIScreenEdgePanGestureRecognizer()
            if let edges = gestureEvent.edges {
                recognizer.edges = edges
            }
            attach(recognizer, on: gestureEvent.states, handler)
        }
        if #available(iOS 13.0, *) {
            if gestureEvent.kind.contains(.hover) {
                let recognizer = UIHoverGestureRecognizer()
                attach(recognizer, on: gestureEvent.states, handler)
            }
        }
    }

    @MainActor
    private func attach<T: UIGestureRecognizer>(
        _ recognizer: T,
        on states: Set<UIGestureRecognizer.State>,
        _ handler: @escaping (_ gesture: T) -> Void
    ) {
        recognizer.cancelsTouchesInView = false
        let box = UIGestureRecognizerSenderEventBox<T>(
            recognizer: recognizer, on: states, actionHandler: handler
        )
        base.addGestureRecognizer(recognizer)
        base.addToPointerPool(box)
    }
}

extension SendingState where Base: UIControl {
    @MainActor
    fileprivate func addControlEventHandler(
        for eventRawValue: UInt,
        _ handler: @escaping (_ sender: UIControl) -> Void
    ) {
        let box = UIControlSenderEventBox(
            control: base,
            on: UIControl.Event(rawValue: eventRawValue),
            actionHandler: handler
        )
        base.addToPointerPool(box)
    }
}
#endif
