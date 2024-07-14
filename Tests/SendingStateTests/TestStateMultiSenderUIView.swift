//
//  TestStateMultiSenderUIView.swift
//  SendingState
//
//  Created by SunSoo Jeon on 23.06.2023.
//

@testable import SendingState

#if os(iOS) || targetEnvironment(macCatalyst)
import UIKit

/// A Configurable + EventForwardingProvider UIView with multiple senders.
@MainActor
final class TestStateMultiSenderUIView: UIView, Configurable, EventForwardingProvider {
    let button = UIButton()
    let toggle = UISwitch()

    var configurer: (TestStateMultiSenderUIView, TestConfigurableUIView.Model) -> Void {
        { cell, model in
            cell.button.setTitle(model.text, for: .normal)
        }
    }

    var eventForwarder: EventForwardable {
        SenderGroup {
            EventForwarder(button) { sender, ctx in
                ctx.control(.touchUpInside) {
                    [TestAction.buttonTapped(sender.tag)]
                }
            }
            EventForwarder(toggle) { sender, ctx in
                ctx.control(.valueChanged) {
                    [TestAction.switchChanged(sender.isOn)]
                }
            }
        }
    }

    override init(frame: CGRect) {
        super.init(frame: .zero)
        addSubview(button)
        addSubview(toggle)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

#endif
