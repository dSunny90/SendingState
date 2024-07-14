//
//  SwiftPointerPool.swift
//  SendingState
//
//  Created by SunSoo Jeon on 24.03.2021.
//

import Foundation

/// A pool that retains `AutoReleasable` objects and ensures they are
/// cleaned up when the pool is deallocated or manually cleared.
///
/// This helps manage resources like gesture recognizer targets,
/// control event handlers, and other closures that may otherwise
/// create retain cycles without explicit cleanup.
///
/// Uses `NSLock` internally for thread safety.
internal final class SwiftPointerPool: @unchecked Sendable {
    /// Internal storage for retained objects conforming to `AutoReleasable`.
    private var items = [AutoReleasable]()
    private let lock = NSLock()

    /// Inserts an object into the pool.
    ///
    /// The pool retains it until deallocation or manual cleanup.
    ///
    /// - Parameter obj: An object conforming to `AutoReleasable`.
    internal func insert(_ obj: AutoReleasable) {
        lock.lock()
        defer { lock.unlock() }
        items.append(obj)
    }

    /// Searches the pool for an object of a given type.
    ///
    /// - Parameter type: The `AutoReleasable`-conforming type to find.
    /// - Returns: The first matching object, or `nil` if none found.
    internal func find<T: AutoReleasable>(ofType type: T.Type) -> T? {
        lock.lock()
        defer { lock.unlock() }
        return items.compactMap { $0 as? T }.first
    }

    /// Removes and cleans up all objects with the specified owner identifier.
    ///
    /// - Parameter identifier: The owner identifier to match.
    internal func remove(owner identifier: ObjectIdentifier) {
        lock.lock()
        defer { lock.unlock() }
        let (toRemove, toKeep) = items.reduce(
            into: ([AutoReleasable](), [AutoReleasable]())
        ) { result, item in
            if item.ownerIdentifier == identifier {
                result.0.append(item)
            } else {
                result.1.append(item)
            }
        }
        toRemove.forEach { $0.cleanup() }
        items = toKeep
    }

    /// Returns whether the pool contains any object with the specified owner.
    ///
    /// - Parameter identifier: The owner identifier to search for.
    /// - Returns: `true` if at least one object in the pool belongs to
    ///   the given owner; otherwise `false`.
    internal func contains(owner identifier: ObjectIdentifier) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return items.contains { $0.ownerIdentifier == identifier }
    }

    /// Cleans up all stored objects and removes them from the pool.
    internal func cleanup() {
        lock.lock()
        defer { lock.unlock() }
        items.forEach { $0.cleanup() }
        items.removeAll()
    }

    deinit {
        cleanup()
    }
}
