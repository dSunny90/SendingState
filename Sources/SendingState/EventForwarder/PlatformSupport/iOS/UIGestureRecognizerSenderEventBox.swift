//
//  UIGestureRecognizerSenderEventBox.swift
//  SendingState
//
//  Created by SunSoo Jeon on 10.10.2021.
//

#if os(iOS) || targetEnvironment(macCatalyst)
import UIKit

/// A wrapper that connects gesture recognizers to action handler closures.
///
/// Retained by a memory pool and releases resources during cleanup
/// to prevent retain cycles.
internal final class UIGestureRecognizerSenderEventBox<T: UIGestureRecognizer>
    : SenderEventBox<T>, @unchecked Sendable
{
    /// Weak reference to the gesture recognizer to prevent retain cycles.
    private weak var recognizer: UIGestureRecognizer?

    /// Gesture states that trigger the handler (e.g., `.recognized`).
    private var allowedStates: Set<UIGestureRecognizer.State> = []

    /// Initializes the box and registers the gesture recognizer.
    ///
    /// - Parameters:
    ///   - recognizer: The gesture recognizer to observe.
    ///   - states: Gesture states that trigger the action (default: `.recognized`).
    ///   - actionHandler: The closure invoked when the gesture occurs.
    @MainActor
    @inlinable
    internal init(
        recognizer: T,
        on states: Set<UIGestureRecognizer.State> = [.recognized],
        actionHandler: @escaping (T) -> Void
    ) {
        self.allowedStates = states
        self.recognizer = recognizer
        super.init(actionHandler)
        recognizer.addTarget(self, action: #selector(invoke(_:)))
    }

    /// Invoked when the gesture recognizer's state changes.
    @MainActor
    @objc override func invoke(_ sender: Any) {
        guard let recognizer = sender as? T else { return }
        guard allowedStates.isEmpty || allowedStates.contains(recognizer.state)
        else { return }
        box?(recognizer)
    }

    /// Removes the target-action and clears references to prevent leaks.
    ///
    /// Typically invoked by `SwiftPointerPool` during deallocation.
    /// When called from the main thread (e.g., explicit `assign`/`remove`),
    /// cleanup runs synchronously so the gesture recognizer is fully
    /// detached before any new handler is added.
    /// When called from a background thread (e.g., `deinit`), cleanup
    /// is dispatched to the main queue asynchronously.
    override func cleanup() {
        let detach = {
            guard let recognizer = self.recognizer else { return }
            recognizer.view?.removeGestureRecognizer(recognizer)
            recognizer.removeTarget(
                self, action: #selector(self.invoke(_:))
            )
            self.recognizer = nil
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
