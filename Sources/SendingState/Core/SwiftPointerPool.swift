//
//  SwiftPointerPool.swift
//  SendingState
//
//  Created by SunSoo Jeon on 30.07.2021.
//

import Foundation

/// A pool that retains `AutoReleasable` objects and ensures they are properly
/// cleaned up when the pool is deallocated or manually cleared.
///
/// This pattern helps manage memory for objects like gesture recognizers,
/// target-action handlers, and other UIKit closures that may otherwise lead
/// to retain cycles if not explicitly released.
///
/// - Note: Thread safety is ensured using an internal `NSLock`.
internal final class SwiftPointerPool {
    /// Internal storage for retained objects conforming to `AutoReleasable`.
    private var items = [AutoReleasable]()
    private let lock = NSLock()

    /// Inserts a new object into the pool. The pool retains it until cleanup.
    ///
    /// - Parameter obj: An object conforming to `AutoReleasable`.
    internal func insert(_ obj: AutoReleasable) {
        lock.lock()
        defer { lock.unlock() }
        items.append(obj)
    }

    /// Searches the pool for an object of the given type.
    ///
    /// - Parameter type: The specific `AutoReleasable`-conforming type to find.
    /// - Returns: The first match of that type if any, otherwise `nil`.
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
