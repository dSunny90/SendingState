//
//  TestEventForwardableUIView.swift
//  SendingState
//
//  Created by SunSoo Jeon on 23.06.2023.
//

@testable import SendingState

#if os(iOS) || targetEnvironment(macCatalyst)
import UIKit

@MainActor
final class TestEventForwardableUIView: UIView, EventForwardingProvider {
    let forwarder: EventForwardable

    var eventForwarder: EventForwardable {
        forwarder
    }

    init(forwarder: EventForwardable) {
        self.forwarder = forwarder
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
#endif
