//
//  EventForwarderTests.swift
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
@MainActor
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

@MainActor
final class EventForwarderViewTestView: UIView, EventForwardingProvider {
    let view = UIView()

    var eventForwarder: EventForwardable {
        EventForwarder(view) { _, ctx in
            ctx.tapGesture() { [TestAction.viewTapped] }
            ctx.pinchGesture { [TestAction.viewPinched] }
        }
    }
}

final class EventForwarderTests: XCTestCase {
    @MainActor
    func test_button_addTarget_wired() {
        let provider = EventForwarderButtonTestView()
        let handler = TestActionHandler()

        provider.ss.assignActionHandler(to: handler)

        let targets = provider.button.allTargets
        XCTAssertEqual(targets.count, 1)

        let actions = provider.button.actions(forTarget: targets.first, forControlEvent: .touchUpInside)
        XCTAssertNotNil(actions)
        XCTAssertTrue(actions?.contains(where: { $0.contains("invoke") }) == true)
    }

    @MainActor
    func test_tapAndPinchGestureRecognizers_areAdded() {
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
#endif
