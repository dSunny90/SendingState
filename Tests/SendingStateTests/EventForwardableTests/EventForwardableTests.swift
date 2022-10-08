//
//  EventForwardableTests.swift
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

final class EventForwardableTests: XCTestCase {}

#if os(iOS) || targetEnvironment(macCatalyst)
import UIKit

final class EventForwarderButtonTestView: UIView, EventForwardingProvider {
    let button = UIButton()

    var eventForwarder: EventForwardable {
        EventForwarder(button) { sender, ctx in
            ctx.control([.touchUpInside]) {
                [TestAction.buttonTapped(sender.tag)]
            }
        }
    }
}

final class EventForwarderViewTestView: UIView, EventForwardingProvider {
    let view = UIView()

    var eventForwarder: EventForwardable {
        EventForwarder(view) { _, ctx in
            ctx.tapGesture() { [TestAction.viewTapped] }
            ctx.pinchGesture { [TestAction.viewPinched] }
        }
    }
}

extension EventForwardableTests {
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

    func test_button_addTarget_wired_with_typeErased_actionHandler() {
        DispatchQueue.main.async {
            let provider = EventForwarderButtonTestView()
            let handler = TestActionHandler()
            let anyActionHandler = AnyActionHandlingProvider(handler)

            provider.ss.assignAnyActionHandler(to: anyActionHandler)

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
