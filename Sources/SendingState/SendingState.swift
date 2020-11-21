//
//  SendingState.swift
//  SendingState
//
//  Created by SunSoo Jeon on 2020/11/20.
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
