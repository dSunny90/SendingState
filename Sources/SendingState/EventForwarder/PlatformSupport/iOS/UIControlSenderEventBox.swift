//
//  UIControlSenderEventBox.swift
//  SendingState
//
//  Created by SunSoo Jeon on 10.10.2021.
//

#if os(iOS) || targetEnvironment(macCatalyst)
import UIKit

/// A wrapper that connects a UIControl event to an action handler closure.
///
/// This box is retained by a memory pool and releases the closure and target
/// registration during cleanup to break retain cycles.
internal final class UIControlSenderEventBox
    : SenderEventBox<UIControl>, @unchecked Sendable
{
    /// Weak reference to the control to avoid retain cycle.
    private weak var control: UIControl?

    /// The specific UIControl event being handled.
    private let event: UIControl.Event

    /// Initializes the box and registers the action for the control event.
    ///
    /// - Parameters:
    ///   - control: The UIControl to attach the action to.
    ///   - events: The event to handle (e.g., .touchUpInside).
    ///   - actionHandler: The closure to invoke on event.
    @MainActor
    @inlinable
    internal init(
        control: UIControl,
        on events: UIControl.Event,
        actionHandler: @escaping (UIControl) -> Void
    ) {
        self.control = control
        self.event = events
        super.init(actionHandler)
        control.addTarget(self, action: #selector(invoke(_:)), for: event)
    }

    /// Removes the target-action and clears references to prevent leaks.
    ///
    /// Typically invoked by `SwiftPointerPool` during deallocation.
    /// When called from the main thread (e.g., explicit `assign`/`remove`),
    /// cleanup runs synchronously so the target-action is fully
    /// detached before any new handler is added.
    /// When called from a background thread (e.g., `deinit`), cleanup
    /// is dispatched to the main queue asynchronously.
    override func cleanup() {
        if Thread.isMainThread {
            self.control?.removeTarget(
                self, action: #selector(self.invoke(_:)), for: self.event
            )
            self.control = nil
        } else {
            DispatchQueue.main.async {
                self.control?.removeTarget(
                    self, action: #selector(self.invoke(_:)), for: self.event
                )
                self.control = nil
            }
        }
        super.cleanup()
    }
}
#endif
