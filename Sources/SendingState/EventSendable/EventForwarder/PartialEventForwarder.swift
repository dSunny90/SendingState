//
//  PartialEventForwarder.swift
//  SendingState
//
//  Created by SunSoo Jeon on 15.05.2021.
//

public struct PartialEventForwarder<Action> {
    public let sender: AnyObject
    public let mapping: [SenderEvent: [Action]]

    public func actions(for event: SenderEvent) -> [Action] {
        mapping[event] ?? []
    }
}
