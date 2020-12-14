//
//  SendingState.swift
//  SendingState
//
//  Created by SunSoo Jeon on 20.11.2020.
//

import Foundation

/// A namespace wrapper that provides SendingState functionality
/// through the `.ss` accessor.
///
/// `SendingState` itself is stateless; it simply holds a reference to
/// the `base` object and exposes extended behaviour via constrained
/// extensions.
public struct SendingState<Base> {
    public let base: Base

    @inlinable
    public init(_ base: Base) { self.base = base }
}

/// Conforming types gain a `.ss` namespace accessor that returns
/// `SendingState<Self>`, enabling the library's extensions.
public protocol SendingStateHost {}
extension SendingStateHost {
    @inlinable
    public var ss: SendingState<Self> { SendingState(self) }

    @inlinable
    public static var ss: SendingState<Self>.Type { SendingState<Self>.self }
}

#if os(iOS) || targetEnvironment(macCatalyst)
import UIKit

extension UIView: SendingStateHost {}
#endif

extension SendingState where Base: NSObject {
    /// Replaces the currently bound state by applying a pure transform.
    ///
    /// - Parameter transform: A closure that returns a new state derived
    ///                        from the current one.
    public func invalidateState<T>(_ transform: (T) -> T) {
        guard let current = base.boundState as? T else { return }
        let newValue = transform(current)
        base.stateObserver?.update(newValue)
    }
}

extension SendingState where Base: Configurable {
    /// Applies the given input to the base object via its `configurer`,
    /// automatically storing the input as the object's state.
    ///
    /// When the base is an `NSObject` (e.g., `UIView`), an internal
    /// ``StateObserver`` is lazily created and attached. The observer:
    /// 1. Stores the input as the current state
    /// 2. Calls the base's `configurer` to update the UI
    ///
    /// For non-`NSObject` bases, falls back to direct `configurer` invocation.
    public func configure<T>(_ input: T) where T == Base.Input {
        guard let object = base as? NSObject else {
            base.configurer(base, input)
            return
        }
        let observer = ensureObserver(on: object)
        observer.update(input)
    }

    private func ensureObserver(on object: NSObject) -> StateObserver {
        if let existing = object.stateObserver {
            return existing
        }

        let observer = StateObserver()
        observer.binder = object
        observer.configureBlock = { [weak base] state in
            guard let base = base,
                  let input = state as? Base.Input else { return }
            base.configurer(base, input)
        }
        object.stateObserver = observer
        return observer
    }
}
