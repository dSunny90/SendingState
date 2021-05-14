//
//  EventForwarderGroup.swift
//  SendingState
//
//  Created by SunSoo Jeon on 15.05.2021.
//

public struct EventForwarderGroup<Action>: EventSendable {
    public typealias Sender = AnyObject

    private let storage: [PartialEventForwarder<Action>]

    public init(_ storage: [PartialEventForwarder<Action>]) { self.storage = storage }

    public func actions(for sender: Sender, event: SenderEvent) -> [Action] {
        storage.flatMap { $0.sender === sender ? $0.actions(for: event) : [] }
    }

    internal var all: [PartialEventForwarder<Action>] { storage }
}
