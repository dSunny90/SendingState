//
//  SendingState.swift
//  SendingState
//
//  Created by SunSoo Jeon on 23.11.2020.
//

public struct SendingState<Base> {
    public let base: Base
    public init(_ base: Base) { self.base = base }
}

public protocol SendingStateHost {}
extension SendingStateHost {
    public var ss: SendingState<Self> { SendingState(self) }
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
