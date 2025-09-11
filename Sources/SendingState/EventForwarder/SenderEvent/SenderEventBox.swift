//
//  SenderEventBox.swift
//  SendingState
//
//  Created by SunSoo Jeon on 19.09.2021.
//

import Foundation

/// A base class that wraps an event handler closure for a specific sender type.
///
/// Used to handle UI event callbacks (e.g., target-actions).
/// Supports Objective-C selector compatibility and manual cleanup.
@usableFromInline
internal class SenderEventBox<Sender>: NSObject, AutoReleasable {
    /// The closure to be invoked when the event occurs.
    @usableFromInline
    internal var box: ((_ sender: Sender) -> Void)?

    /// An optional identifier for the owner of this resource.
    @usableFromInline
    internal var ownerIdentifier: ObjectIdentifier?

    /// Initializes the box with a closure.
    ///
    /// - Parameter box: A closure taking a sender of type `Sender`.
    @inlinable
    internal init(_ box: @escaping (_ sender: Sender) -> Void) {
        self.box = box
    }

    /// Invokes the stored closure using the provided sender object.
    ///
    /// - Parameter sender: The sender object that triggered the event.
    ///   This will be type-checked against the expected sender type at runtime.
    @MainActor
    @objc internal func invoke(_ sender: Any) {
        guard let sender = sender as? Sender else { return }
        box?(sender)
    }

    /// Clears the stored closure to break potential retain cycles.
    ///
    /// Called by memory pool managers to release memory early.
    nonisolated internal func cleanup() {
        box = nil
    }
}
