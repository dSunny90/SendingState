//
//  SendingState.swift
//  SendingState
//
//  Created by SunSoo Jeon on 20.11.2020.
//

/// A namespace wrapper that provides SendingState functionality
/// through the `.ss` accessor.
///
/// `SendingState` itself is stateless; it simply holds a reference to
/// the `base` object and exposes extended behaviour via constrained
/// extensions.
public struct SendingState<Base> {
    public let base: Base

    @inlinable
    public init(_ base: Base) { self.base = base }
}

extension SendingState where Base: Configurable {
    /// Sugar for `configurer(self, input)`
    public func configure<T>(_ input: T) where T == Base.Input {
        base.configurer(base, input)
    }
}

/// Conforming types gain a `.ss` namespace accessor that returns
/// `SendingState<Self>`, enabling the library's extensions.
public protocol SendingStateHost {}
extension SendingStateHost {
    @inlinable
    public var ss: SendingState<Self> { SendingState(self) }

    @inlinable
    public static var ss: SendingState<Self>.Type { SendingState<Self>.self }
}

/// A closure factory that, given a sender–event pair from an
/// ``EventSendable`` mapping, returns a handler closure to be
/// invoked when that event fires.
fileprivate typealias ActionHandlerBlock =
    (_ sender: AnyObject, _ event: SenderEvent) -> (_ sender: AnyObject) -> Void


#if os(iOS) || targetEnvironment(macCatalyst)
import UIKit

extension SendingState where Base: UIView & EventSendingProvider {
    // MARK: - Add

    /// Registers the typed action handler so it receives events forwarded
    /// by this view's ``EventSendable`` mappings.
    ///
    /// The handler is identified by its `ObjectIdentifier`, so adding the
    /// same instance again is a no-op (idempotent).
    ///
    /// - Parameter provider: The handler to register.
    public func addActionHandler<Provider: ActionHandlingProvider>(
        to provider: Provider
    ) {
        let ownerID = ObjectIdentifier(provider)
        addEventHandlers(owner: ownerID) { sender, event in
            { [weak base, weak sender, weak provider] _ in
                guard let base = base, let sender = sender, let provider = provider
                else { return }
                let actions = base.eventForwarder.actions(for: sender,
                                                          event: event)
                for case let action as Provider.Action in actions {
                    provider.handle(action: action)
                }
            }
        }
    }

    /// Registers the type-erased action handler so it receives events
    /// forwarded by this view's ``EventSendable`` mappings.
    ///
    /// The handler is identified by its `ObjectIdentifier`, so adding the
    /// same instance again is a no-op (idempotent).
    ///
    /// - Parameter provider: The type-erased handler to register.
    public func addAnyActionHandler(to provider: AnyActionHandlingProvider) {
        let ownerID = ObjectIdentifier(provider)
        addEventHandlers(owner: ownerID) { sender, event in
            { [weak base, weak sender, weak provider] _ in
                guard let base = base, let sender = sender, let provider = provider
                else { return }
                let actions = base.eventForwarder.actions(for: sender,
                                                          event: event)
                for action in actions {
                    provider.handle(action: action)
                }
            }
        }
    }

    // MARK: - Remove

    /// Removes the typed action handler from this view, cleaning up all
    /// event bindings that were created by ``addActionHandler(to:)``.
    ///
    /// - Parameter provider: The handler to remove.
    public func removeActionHandler<Provider: ActionHandlingProvider>(
        from provider: Provider
    ) {
        let ownerID = ObjectIdentifier(provider)
        removeEventHandlers(owner: ownerID)
    }

    /// Removes the type-erased action handler from this view, cleaning up
    /// all event bindings that were created by ``addAnyActionHandler(to:)``.
    ///
    /// - Parameter provider: The type-erased handler to remove.
    public func removeAnyActionHandler(from provider: AnyActionHandlingProvider) {
        let ownerID = ObjectIdentifier(provider)
        removeEventHandlers(owner: ownerID)
    }

    /// Removes **all** action handlers from this view and its senders,
    /// regardless of owner.
    public func removeAllActionHandlers() {
        for (sender, _, _) in base.eventForwarder.allMappings {
            (sender as? NSObject)?.cleanupPointerPool()
        }
        base.cleanupPointerPool()
    }

    // MARK: - Assign (replace)

    /// Removes all existing action handlers, then registers the given
    /// typed handler as the sole receiver of this view's forwarded events.
    ///
    /// - Parameter provider: The handler to assign.
    public func assignActionHandler<Provider: ActionHandlingProvider>(
        to provider: Provider
    ) {
        removeAllActionHandlers()
        addActionHandler(to: provider)
    }

    /// Removes all existing action handlers, then registers the given
    /// type-erased handler as the sole receiver of this view's forwarded
    /// events.
    ///
    /// - Parameter provider: The type-erased handler to assign.
    public func assignAnyActionHandler(to provider: AnyActionHandlingProvider) {
        removeAllActionHandlers()
        addAnyActionHandler(to: provider)
    }

    // MARK: - Private Helpers

    /// Iterates through the base view's event forwarder mappings and
    /// registers gesture recognizer or control-event handlers for each
    /// sender–event pair.
    ///
    /// This method is idempotent: if the owner already has handlers
    /// registered on a sender, the call is a no-op. This makes it safe
    /// to invoke repeatedly (e.g. on every `cellForItemAt` call) without
    /// accumulating duplicate handlers.
    ///
    /// - Parameters:
    ///   - owner: An identifier that groups the created handler boxes,
    ///     allowing batch removal later via ``removeEventHandlers(owner:)``.
    ///   - handlerBlock: A factory that produces a handler closure for a
    ///     given sender–event pair.
    private func addEventHandlers(
        owner: ObjectIdentifier,
        using handlerBlock: @escaping ActionHandlerBlock
    ) {
        let allMappings = base.eventForwarder.allMappings
        guard let firstSender = allMappings.first?.sender as? NSObject,
              !firstSender.containsInPointerPool(owner: owner)
        else { return }
        for (sender, event, _) in allMappings {
            let handler = handlerBlock(sender, event)
            switch event {
            case .gesture(let gesture):
                guard let v = sender as? UIView else { return }
                v.ss.addGestureHandler(handler, for: gesture, owner: owner)

            case .control(let controlEvent):
                guard let c = sender as? UIControl else { return }
                let event = controlEvent.value.rawValue
                c.ss.addControlEventHandler(handler, for: event, owner: owner)
            }
        }
    }

    /// Removes all handler boxes belonging to the given owner from every
    /// sender's pointer pool, then from the base view's own pool.
    ///
    /// - Parameter owner: The identifier whose handler boxes should be
    ///   removed.
    private func removeEventHandlers(owner: ObjectIdentifier) {
        for (sender, _, _) in base.eventForwarder.allMappings {
            (sender as? NSObject)?.removeFromPointerPool(owner: owner)
        }
        base.removeFromPointerPool(owner: owner)
    }
}

extension SendingState where Base: UIView {
    /// Creates and attaches `UIGestureRecognizer` instances to the base
    /// view based on the kinds specified in the gesture event descriptor.
    ///
    /// - Parameters:
    ///   - handler: The closure invoked when the gesture fires.
    ///   - gestureEvent: The gesture descriptor containing kind, states,
    ///     and optional configuration (tap count, touch count, etc.).
    ///   - owner: The owner identifier for the created handler boxes.
    fileprivate func addGestureHandler(
        _ handler: @escaping (_ gesture: UIGestureRecognizer) -> Void,
        for gestureEvent: SenderEvent.Gesture,
        owner: ObjectIdentifier
    ) {
        if gestureEvent.kind.contains(.tap) {
            let gr = UITapGestureRecognizer()
            if let taps = gestureEvent.numberOfTaps {
                gr.numberOfTapsRequired = taps
            }
            if let touches = gestureEvent.numberOfTouches {
                gr.numberOfTouchesRequired = touches
            }
            attach(gr, on: gestureEvent.states, handler, owner: owner)
        }
        if gestureEvent.kind.contains(.longPress) {
            let gr = UILongPressGestureRecognizer()
            if let duration = gestureEvent.minimumPressDuration {
                gr.minimumPressDuration = duration
            }
            if let taps = gestureEvent.numberOfTaps {
                gr.numberOfTapsRequired = taps
            }
            if let touches = gestureEvent.numberOfTouches {
                gr.numberOfTouchesRequired = touches
            }
            attach(gr, on: gestureEvent.states, handler, owner: owner)
        }
        if gestureEvent.kind.contains(.swipe) {
            let gr = UISwipeGestureRecognizer()
            if let direction = gestureEvent.direction {
                gr.direction = direction
            }
            if let touches = gestureEvent.numberOfTouches {
                gr.numberOfTouchesRequired = touches
            }
            attach(gr, on: gestureEvent.states, handler, owner: owner)
        }
        if gestureEvent.kind.contains(.pan) {
            let gr = UIPanGestureRecognizer()
            if let touches = gestureEvent.numberOfTouches {
                gr.minimumNumberOfTouches = touches
            }
            attach(gr, on: gestureEvent.states, handler, owner: owner)
        }
        if gestureEvent.kind.contains(.pinch) {
            let gr = UIPinchGestureRecognizer()
            attach(gr, on: gestureEvent.states, handler, owner: owner)
        }
        if gestureEvent.kind.contains(.rotation) {
            let gr = UIRotationGestureRecognizer()
            attach(gr, on: gestureEvent.states, handler, owner: owner)
        }
        if gestureEvent.kind.contains(.screenEdge) {
            let gr = UIScreenEdgePanGestureRecognizer()
            if let edges = gestureEvent.edges {
                gr.edges = edges
            }
            attach(gr, on: gestureEvent.states, handler, owner: owner)
        }
        if #available(iOS 13.0, *) {
            if gestureEvent.kind.contains(.hover) {
                let gr = UIHoverGestureRecognizer()
                attach(gr, on: gestureEvent.states, handler, owner: owner)
            }
        }
    }

    /// Configures a gesture recognizer, adds it to the base view, and
    /// stores the handler box in the view's pointer pool.
    ///
    /// - Parameters:
    ///   - gestureRecognizer: The gesture recognizer to attach.
    ///   - states: The recognizer states that should trigger the handler.
    ///   - handler: The closure invoked when the gesture fires.
    ///   - owner: The owner identifier for the created handler box.
    private func attach<T: UIGestureRecognizer>(
        _ gestureRecognizer: T,
        on states: Set<UIGestureRecognizer.State>,
        _ handler: @escaping (_ gesture: T) -> Void,
        owner: ObjectIdentifier
    ) {
        gestureRecognizer.cancelsTouchesInView = false
        let box = UIGestureRecognizerSenderEventBox<T>(
            recognizer: gestureRecognizer, on: states, actionHandler: handler
        )
        if Thread.isMainThread {
            base.addGestureRecognizer(gestureRecognizer)
        } else {
            DispatchQueue.main.async {
                base.addGestureRecognizer(gestureRecognizer)
            }
        }
        base.addToPointerPool(box, owner: owner)
    }
}

extension SendingState where Base: UIControl {
    /// Registers a control-event handler on the base control and stores
    /// the handler box in the control's pointer pool.
    ///
    /// - Parameters:
    ///   - eventRawValue: The raw value of the `UIControl.Event` to observe.
    ///   - handler: The closure invoked when the control event fires.
    ///   - owner: The owner identifier for the created handler box.
    fileprivate func addControlEventHandler(
        _ handler: @escaping (_ sender: UIControl) -> Void,
        for eventRawValue: UInt,
        owner: ObjectIdentifier
    ) {
        let box = UIControlSenderEventBox(
            control: base,
            on: UIControl.Event(rawValue: eventRawValue),
            actionHandler: handler
        )
        base.addToPointerPool(box, owner: owner)
    }
}

extension UIView: SendingStateHost {}
#endif
