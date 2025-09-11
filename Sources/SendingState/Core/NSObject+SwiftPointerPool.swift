//
//  NSObject+SwiftPointerPool.swift
//  SendingState
//
//  Created by SunSoo Jeon on 30.07.2021.
//

import Foundation

extension NSObject {
    private struct AssociatedKeys {
        nonisolated(unsafe) static var pool: UInt8 = 0
    }

    private var pointerPool: SwiftPointerPool {
        guard let pool = objc_getAssociatedObject(
            self, &AssociatedKeys.pool
        ) as? SwiftPointerPool
        else {
            let pool = SwiftPointerPool()
            objc_setAssociatedObject(
                self,
                &AssociatedKeys.pool,
                pool,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
            return pool
        }
        return pool
    }

    /// Adds an `AutoReleasable` object to this instance's pointer pool.
    ///
    /// The added object will have its `cleanup()` method called automatically
    /// when this instance is deallocated.
    ///
    /// - Parameter autoReleasable: The object to add to the pool.
    internal func addToPointerPool(_ autoReleasable: AutoReleasable) {
        pointerPool.insert(autoReleasable)
    }

    /// Adds an `AutoReleasable` object to this instance's pointer pool
    /// with an associated owner identifier.
    ///
    /// - Parameters:
    ///   - autoReleasable: The object to add to the pool.
    ///   - owner: The owner identifier for grouping related resources.
    internal func addToPointerPool(
        _ autoReleasable: AutoReleasable,
        owner: ObjectIdentifier
    ) {
        autoReleasable.ownerIdentifier = owner
        pointerPool.insert(autoReleasable)
    }

    /// Removes all objects with the specified owner from the pointer pool.
    ///
    /// - Parameter owner: The owner identifier to match for removal.
    internal func removeFromPointerPool(owner: ObjectIdentifier) {
        pointerPool.remove(owner: owner)
    }

    /// Cleans up and removes all objects from the pointer pool.
    internal func cleanupPointerPool() {
        pointerPool.cleanup()
    }
}
