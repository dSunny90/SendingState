//
//  EventForwarderItem.swift
//  SendingState
//
//  Created by SunSoo Jeon on 15.05.2021.
//

public struct EventForwarderItem<Sender: AnyObject, Action> {
    internal let box: PartialEventForwarder<Action>

    public init(
        _ sender: Sender,
        @EventForwarderItemBuilder<Action> _ builder: () -> [SenderEvent: [Action]]
    ) {
        self.box = PartialEventForwarder(sender: sender, mapping: builder())
    }
}

@resultBuilder
public enum EventForwarderItemBuilder<Action> {
    public static func buildBlock(_ mappings: [SenderEvent: [Action]]...) -> [SenderEvent: [Action]] {
        mappings.reduce(into: [:]) { result, next in
            for (k, v) in next {
                result[k, default: []] += v
            }
        }
    }
}
