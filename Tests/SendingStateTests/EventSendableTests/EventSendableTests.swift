//
//  EventSendableTests.swift
//  SendingState
//
//  Created by SunSoo Jeon on 05.04.2021.
//
// MARK: - Test Notes
// Some UIKit interactions, such as button taps and tap gesture handling,
// cannot be reproduced in XCTest with full runtime fidelity.
// Therefore, the corresponding behaviors were additionally validated
// in a separate sample project under actual runtime conditions.
//

import XCTest

@testable import SendingState

final class EventSendableTests: XCTestCase {}

#if os(iOS) || targetEnvironment(macCatalyst)
import UIKit

final class EventForwarderButtonTestView: UIView, EventSendingProvider {
    let button = UIButton()
    let toggle = UISwitch()
    let slider = UISlider()

    var eventForwarder: EventSendable {
        EventForwarderGroup<TestAction>([
            EventForwarder(sender: button, mappings: [
                .control(.init(.touchUpInside)): { [weak self] in
                    guard let self = self else { return [] }
                    return [.buttonTapped(self.button.tag)]
                }
            ]),
            EventForwarder(sender: toggle, mappings: [
                .control(.init(.valueChanged)): { [weak self] in
                    guard let self = self else { return [] }
                    return [.switchChanged(self.toggle.isOn)]
                }
            ]),
            EventForwarder(sender: slider, mappings: [
                .control(.init(.valueChanged)): { [weak self] in
                    guard let self = self else { return [] }
                    return [.sliderChanged(self.slider.value)]
                }
            ])
        ])
    }
}

final class EventForwarderViewTestView: UIView, EventSendingProvider {
    let view = UIView()

    var eventForwarder: EventSendable {
        EventForwarderGroup<TestAction>([
            EventForwarder(sender: view, mappings: [
                .gesture(.init(kind: .tap)): { return [TestAction.viewTapped] },
                .gesture(.init(kind: .pinch)): { return [TestAction.viewPinched] }
            ])
        ])
    }
}

extension EventSendableTests {
    func test_button_addTarget_wired() {
        DispatchQueue.main.async {
            let provider = EventForwarderButtonTestView()
            let handler = TestActionHandler()

            provider.ss.assignActionHandler(to: handler)

            let targets = provider.button.allTargets
            XCTAssertEqual(targets.count, 1)

            let actions = provider.button.actions(forTarget: targets.first, forControlEvent: .touchUpInside)
            XCTAssertNotNil(actions)
            XCTAssertTrue(actions?.contains(where: { $0.contains("invoke") }) == true)
        }
    }

    func test_tapAndPinchGestureRecognizers_areAdded() {
        DispatchQueue.main.async {
            let provider = EventForwarderViewTestView()
            let handler = TestActionHandler()

            provider.ss.assignActionHandler(to: handler)

            guard let gestures = provider.view.gestureRecognizers else {
                XCTFail("No gesture recognizers attached")
                return
            }
            XCTAssertEqual(gestures.count, 2)

            let tap = gestures.first { $0 is UITapGestureRecognizer } as? UITapGestureRecognizer
            let pinch = gestures.first { $0 is UIPinchGestureRecognizer } as? UIPinchGestureRecognizer

            XCTAssertNotNil(tap)
            XCTAssertNotNil(pinch)
        }
    }
}

#endif

enum TestAction {
    case buttonTapped(Int)
    case switchChanged(Bool)
    case sliderChanged(Float)
    case sendClickLog
    case viewTapped
    case viewPinched
}

final class TestActionHandler: ActionHandlingProvider {
    var handledActions: [TestAction] = []

    func handle(action: TestAction) {
        print(">>> Test Action Handled")
        handledActions.append(action)
    }
}
