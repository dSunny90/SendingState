//
//  UIControlSenderEventBox.swift
//  SendingState
//
//  Created by SunSoo Jeon on 25.03.2021.
//

#if os(iOS) || targetEnvironment(macCatalyst)
import UIKit

/// A wrapper that connects UIControl events to action handler closures.
///
/// Retained by a memory pool and releases resources during cleanup
/// to prevent retain cycles.
internal final class UIControlSenderEventBox: SenderEventBox<UIControl> {
    /// Weak reference to the control to prevent retain cycles.
    private weak var control: UIControl?

    /// The UIControl event being handled.
    private let event: UIControl.Event

    /// Initializes the box and registers the target-action for the control event.
    ///
    /// - Parameters:
    ///   - control: The UIControl to attach the action to.
    ///   - events: The UIControl event to handle (e.g., `.touchUpInside`).
    ///   - actionHandler: The closure invoked when the event occurs.
    @inlinable
    internal init(
        control: UIControl,
        on events: UIControl.Event,
        actionHandler: @escaping (UIControl) -> Void
    ) {
        self.control = control
        self.event = events
        super.init(actionHandler)
        if Thread.isMainThread {
            control.addTarget(self, action: #selector(invoke(_:)), for: event)
        } else {
            DispatchQueue.main.async {
                self.control?.addTarget(
                    self, action: #selector(self.invoke(_:)), for: self.event
                )
            }
        }
    }

    override func cleanup() {
        let detach = {
            guard let control = self.control else { return }
            control.removeTarget(self, action: #selector(self.invoke(_:)), for: self.event)
            self.control = nil
        }

        if Thread.isMainThread {
            detach()
        } else {
            DispatchQueue.main.async(execute: detach)
        }
        super.cleanup()
    }
}
#endif
