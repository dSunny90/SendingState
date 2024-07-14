//
//  TestEventForwardingUIView.swift
//  SendingState
//
//  Created by SunSoo Jeon on 23.06.2023.
//

@testable import SendingState

#if os(iOS) || targetEnvironment(macCatalyst)
import UIKit

@MainActor
final class TestEventForwardingUIView: UIView, EventForwardingProvider {
    let button = UIButton()
    let testSwitch = UISwitch()
    let slider = UISlider()
    let tapView = UIView()

    var eventForwarder: EventForwardable {
        SenderGroup {
            EventForwarder(button) { sender, ctx in
                ctx.control(.touchUpInside) {
                    [TestAction.buttonTapped(sender.tag)]
                }
            }
            EventForwarder(testSwitch) { sender, ctx in
                ctx.control(.valueChanged) {
                    [TestAction.switchChanged(sender.isOn)]
                }
            }
            EventForwarder(slider) { sender, ctx in
                ctx.control(.valueChanged) {
                    [TestAction.sliderChanged(sender.value)]
                }
            }
            EventForwarder(tapView) { _, ctx in
                ctx.tapGesture() {
                    [TestAction.viewTapped]
                }
            }
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(button)
        addSubview(testSwitch)
        addSubview(slider)
        addSubview(tapView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
#endif
