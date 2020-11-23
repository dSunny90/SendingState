//
//  SendingState.swift
//  SendingState
//
//  Created by SunSoo Jeon on 20.11.2020.
//

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

extension SendingState where Base: Configurable {
    /// Sugar for `configurer(self, input)`
    public func configure<T>(_ input: T) where T == Base.Input {
        base.configurer(base, input)
    }
}
