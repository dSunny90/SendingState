//
//  EventForwarder.swift
//  SendingState
//
//  Created by SunSoo Jeon on 15.05.2021.
//

public struct EventForwarder<Action> {
    private let box: EventForwarderGroup<Action>

    public init(@EventForwarderBuilder<Action> _ content: () -> [PartialEventForwarder<Action>]) {
        self.box = EventForwarderGroup(content())
    }

    public func eraseToEventForwarderGroup() -> EventForwarderGroup<Action> { box }
}

extension EventForwarder: EventSendable {
    public typealias Sender = AnyObject

    public func actions(for sender: AnyObject, event: SenderEvent) -> [Action] {
        box.actions(for: sender, event: event)
    }
}

@resultBuilder
public enum EventForwarderBuilder<Action> {
    public static func buildBlock(_ components: EventForwarderItem<AnyObject, Action>...) -> [PartialEventForwarder<Action>] {
        components.map { $0.box }
    }
}
