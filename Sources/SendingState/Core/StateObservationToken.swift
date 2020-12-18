//
//  StateObservationToken.swift
//  SendingState
//
//  Created by SunSoo Jeon on 18.12.2020.
//

import Foundation

/// A token that represents an active state observation.
///
/// `StateObservationToken` is returned when registering an observer for
/// state changes. Hold this token for as long as you want the observation
/// to remain active.
///
/// Calling ``cancel()`` removes the underlying observation immediately.
/// If the token is released without an explicit cancellation, it cancels
/// itself automatically in `deinit`.
///
/// This type is useful for managing the lifetime of state observation
/// without exposing the observer storage implementation.
public final class StateObservationToken {
    private let cancellation: () -> Void
    private let lock = NSLock()
    private var isCancelled = false

    /// Creates a token with the given cancellation closure.
    ///
    /// - Parameter cancellation: A closure that removes the underlying
    ///                           observation when the token is cancelled
    ///                           or deallocated.
    public init(_ cancellation: @escaping () -> Void) {
        self.cancellation = cancellation
    }

    /// Cancels the observation and releases the underlying observer.
    ///
    /// Calling this method more than once has no additional effect.
    /// After cancellation, the underlying observer is removed and will no
    /// longer respond to future state changes.
    public func cancel() {
        lock.lock()
        defer { lock.unlock() }

        guard isCancelled == false else { return }
        isCancelled = true
        cancellation()
    }

    deinit {
        cancel()
    }
}
