//
//  SenderGroupTests.swift
//  SendingState
//
//  Created by SunSoo Jeon on 03.10.2022.
//

import XCTest

@testable import SendingState

#if os(iOS) || targetEnvironment(macCatalyst)
import UIKit
#endif
#if os(macOS) && !targetEnvironment(macCatalyst)
import AppKit
#endif

#if os(iOS) || targetEnvironment(macCatalyst)
final class SenderGroupControlsTestView: UIView, EventForwardingProvider {
    let testButton = UIButton()
    let testSwitch = UISwitch()
    let testSlider = UISlider()
    let testView = UIView()

    var eventForwarder: EventForwardable {
        SenderGroup {
            EventForwarder(testButton) { sender, ctx in
                ctx.control([.touchUpInside]) {
                    [
                        TestAction
                            .buttonTapped(sender.tag),
                            .sendClickLog
                    ]
                }
            }
            EventForwarder(testSwitch) { sender, ctx in
                ctx.control([.valueChanged]) {
                    [TestAction.switchChanged(sender.isOn)]
                }
            }
            EventForwarder(testSlider) { sender, ctx in
                ctx.control([.valueChanged]) {
                    [TestAction.sliderChanged(sender.value)]
                }
            }
            EventForwarder(testView) { _, ctx in
                ctx.tapGesture() {
                    [TestAction.viewTapped]
                }
            }
        }
    }
}

final class SenderGroupTests: XCTestCase {
    func test_senderGroup_allTargets_addTarget_wired() {
        DispatchQueue.main.async {
            let provider = SenderGroupControlsTestView()
            let handler = TestActionHandler()
            
            provider.ss.assignActionHandler(to: handler)
            
            let buttonTargets = provider.testButton.allTargets
            XCTAssertTrue(buttonTargets.count == 1)
            
            let buttonActions = provider.testButton.actions(forTarget: buttonTargets.first, forControlEvent: .touchUpInside)
            XCTAssertNotNil(buttonActions)
            XCTAssertTrue(buttonActions?.contains(where: { $0.contains("invoke") }) == true)
            
            let switchTargets = provider.testSwitch.allTargets
            XCTAssertTrue(switchTargets.count > 0)
            
            let switchActions = provider.testSwitch.actions(forTarget: switchTargets.first, forControlEvent: .valueChanged)
            XCTAssertNotNil(switchActions)
            XCTAssertTrue(switchActions?.contains(where: { $0.contains("invoke") }) == true)
            
            let sliderTargets = provider.testSlider.allTargets
            XCTAssertTrue(sliderTargets.count > 0)
            
            let sliderActions = provider.testSlider.actions(forTarget: sliderTargets.first, forControlEvent: .valueChanged)
            XCTAssertNotNil(sliderActions)
            XCTAssertTrue(sliderActions?.contains(where: { $0.contains("invoke") }) == true)
            
            guard let gestures = provider.testView.gestureRecognizers else {
                XCTFail("No gesture recognizers attached")
                return
            }
            XCTAssertEqual(gestures.count, 1)
            
            let tap = gestures.first { $0 is UITapGestureRecognizer } as? UITapGestureRecognizer
            XCTAssertNotNil(tap)
        }
    }
}
#endif
