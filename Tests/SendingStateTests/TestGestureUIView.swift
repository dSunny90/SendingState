//
//  TestGestureUIView.swift
//  SendingState
//
//  Created by SunSoo Jeon on 23.06.2023.
//

@testable import SendingState

#if os(iOS) || targetEnvironment(macCatalyst)
import UIKit

@MainActor
final class TestGestureUIView: UIView, EventForwardingProvider {
    let view = UIView()

    var eventForwarder: EventForwardable {
        EventForwarder(view) { _, ctx in
            ctx.tapGesture() {
                [TestAction.viewTapped]
            }
            ctx.pinchGesture(on: [.began, .changed, .ended]) {
                [TestAction.viewPinched]
            }
            ctx.panGesture(on: [.began, .changed, .ended]) {
                [TestAction.viewPanned]
            }
            ctx.longPressGesture(on: [.began, .ended]) {
                [TestAction.longPressed]
            }
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(view)
        view.frame = bounds
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
#endif
