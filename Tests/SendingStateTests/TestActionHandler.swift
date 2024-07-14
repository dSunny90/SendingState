//
//  TestActionHandler.swift
//  SendingState
//
//  Created by SunSoo Jeon on 23.06.2023.
//

import Foundation
@testable import SendingState

final class TestActionHandler: ActionHandlingProvider, @unchecked Sendable {
    private let lock = NSLock()
    private var _handledActions: [TestAction] = []
    private var _callCount = 0

    init() {}

    var handledActions: [TestAction] {
        lock.lock()
        defer { lock.unlock() }
        return _handledActions
    }

    var callCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return _callCount
    }

    func handle(action: TestAction) {
        lock.lock()
        defer { lock.unlock() }

        _callCount += 1
        _handledActions.append(action)
    }

    func reset() {
        lock.lock()
        defer { lock.unlock() }

        _handledActions.removeAll()
        _callCount = 0
    }
}
