//
//  SenderEventBox.swift
//  SendingState
//
//  Created by SunSoo Jeon on 25.03.2021.
//

import Foundation

/// A base class that wraps an event handler closure for a specific sender type.
///
/// Handles UI event callbacks (e.g., target-action patterns).
/// Compatible with Objective-C selectors and supports manual cleanup.
@usableFromInline
internal class SenderEventBox<Sender>: NSObject, AutoReleasable {
    /// The closure invoked when the event occurs.
    @usableFromInline
    internal var box: ((_ sender: Sender) -> Void)?

    /// An optional identifier for the owner of this resource.
    @usableFromInline
    internal var ownerIdentifier: ObjectIdentifier?

    /// Initializes the box with a closure.
    ///
    /// - Parameter box: A closure that receives the sender.
    @inlinable
    internal init(_ box: @escaping (_ sender: Sender) -> Void) {
        self.box = box
    }

    /// Invokes the stored closure with the sender.
    ///
    /// - Parameter sender: The object that triggered the event.
    @objc internal func invoke(_ sender: Any) {
        guard let sender = sender as? Sender else { return }
        if Thread.isMainThread {
            box?(sender)
        } else {
            DispatchQueue.main.async {
                self.box?(sender)
            }
        }
    }

    /// Clears the stored closure to prevent retain cycles.
    ///
    /// Typically invoked by `SwiftPointerPool` during cleanup.
    internal func cleanup() {
        box = nil
    }
}
