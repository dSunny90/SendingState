//
//  NSObject+SwiftPointerPool.swift
//  SendingState
//
//  Created by SunSoo Jeon on 30.07.2021.
//

import Foundation

extension NSObject {
    private struct AssociatedKeys {
        static var pool: UInt8 = 0
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

    internal func addToPointerPool(_ autoReleaseable: AutoReleasable) {
        pointerPool.insert(autoReleaseable)
    }
}
