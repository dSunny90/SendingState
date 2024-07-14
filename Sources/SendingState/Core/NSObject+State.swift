//
//  NSObject+State.swift
//  SendingState
//
//  Created by SunSoo Jeon on 23.04.2021.
//

import Foundation

extension NSObject {
    private struct AssociatedKeys {
        nonisolated(unsafe) static var boundState: UInt8 = 0
        nonisolated(unsafe) static var stateObserver: UInt8 = 0
    }

    /// A bound state slot stored as an associated object.
    ///
    /// Automatically released when the host object is deallocated.
    /// Struct values are boxed into `_SwiftValue` by the ObjC runtime.
    /// Class values are strongly retained and their `deinit` is called
    /// on release.
    @usableFromInline
    internal var boundState: Any? {
        get {
            objc_getAssociatedObject(self, &AssociatedKeys.boundState)
        }
        set {
            objc_setAssociatedObject(
                self,
                &AssociatedKeys.boundState,
                newValue,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
    }

    /// The state observer attached to this object.
    ///
    /// Created and attached by `SendingState.configure(_:)` on first use.
    @MainActor
    internal var stateObserver: StateObserver? {
        get {
            objc_getAssociatedObject(
                self, &AssociatedKeys.stateObserver
            ) as? StateObserver
        }
        set {
            objc_setAssociatedObject(
                self,
                &AssociatedKeys.stateObserver,
                newValue,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
    }
}

extension SendingState where Base: NSObject {
    /// Retrieves the stored state, cast to the inferred type.
    ///
    /// Returns `nil` if no state has been stored or if the stored
    /// value's type does not match `T`.
    ///
    /// ### Example:
    /// ```swift
    /// // Inside an EventForwarder closure:
    /// let model: MyModel? = sender.ss.state()
    ///
    /// // Inside a selector-based handler:
    /// let model: MyModel? = self.ss.state()
    /// ```
    @inlinable
    public func state<T>() -> T? {
        base.boundState as? T
    }

    /// Removes the stored state from the base object and its observer.
    @MainActor
    public func removeState() {
        base.boundState = nil
        base.stateObserver?.state = nil
    }
}

extension SendingState where Base: Configurable & NSObject {
    /// Retrieves the stored state as the binder's `Input` type.
    ///
    /// Because the base conforms to `Configurable`, the compiler knows
    /// `Input` at the call site — no explicit type annotation needed.
    ///
    /// ### Example:
    /// ```swift
    /// let model = cell.ss.state()   // → MyModel?
    /// ```
    @inlinable
    public func state() -> Base.Input? {
        base.boundState as? Base.Input
    }
}
