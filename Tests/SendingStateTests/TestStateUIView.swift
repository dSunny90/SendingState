//
//  TestStateUIView.swift
//  SendingState
//
//  Created by SunSoo Jeon on 23.06.2023.
//

@testable import SendingState

#if os(iOS) || targetEnvironment(macCatalyst)
import UIKit

/// A Configurable + EventForwardingProvider UIView for testing state propagation
/// to a single sender.
@MainActor
final class TestStateUIView: UIView, Configurable, EventForwardingProvider {
    let button = UIButton()

    var configurer: (TestStateUIView, TestConfigurableUIView.Model) -> Void {
        { cell, model in
            cell.button.setTitle(model.text, for: .normal)
        }
    }

    var eventForwarder: EventForwardable {
        EventForwarder(button) { sender, ctx in
            ctx.control(.touchUpInside) {
                [TestAction.buttonTapped(sender.tag)]
            }
        }
    }

    override init(frame: CGRect) {
        super.init(frame: .zero)
        addSubview(button)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

#endif
