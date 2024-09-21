//
//  UIGestureRecognizerSenderEventBox.swift
//  SendingState
//
//  Created by SunSoo Jeon on 10.10.2021.
//

#if os(iOS) || targetEnvironment(macCatalyst)
import UIKit

/// A wrapper that connects a UIGestureRecognizer to an action handler closure.
///
/// This box is retained by a memory pool and releases the closure and target
/// registration during cleanup to break retain cycles.
internal final class UIGestureRecognizerSenderEventBox<T: UIGestureRecognizer>
    : SenderEventBox<T>, @unchecked Sendable
{
    /// Weak reference to the gesture recognizer to avoid retain cycle.
    private weak var recognizer: UIGestureRecognizer?

    /// Allowed states to invoke the handler (e.g., [.recognized]).
    private var allowedStates: Set<UIGestureRecognizer.State> = []

    /// Initializes the box and registers the gesture recognizer.
    ///
    /// - Parameters:
    ///   - recognizer: The gesture recognizer to observe.
    ///   - states: Gesture states that trigger the action.
    ///   - actionHandler: The closure to invoke on gesture event.
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

    /// Called by the system when the gesture is triggered.
    @MainActor
    @objc override func invoke(_ sender: Any) {
        guard let recognizer = sender as? T else { return }
        guard allowedStates.isEmpty || allowedStates.contains(recognizer.state)
        else { return }
        box?(recognizer)
    }

    /// Cleans up gesture recognizer registration and memory references.
    override func cleanup() {
        DispatchQueue.main.async {
            self.recognizer?.removeTarget(
                self, action: #selector(self.invoke(_:))
            )
            self.recognizer = nil
        }
        super.cleanup()
    }
}
#endif
