//
//  TestActionHandler.swift
//  SendingState
//
//  Created by SunSoo Jeon on 03.10.2022.
//

@testable import SendingState

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
