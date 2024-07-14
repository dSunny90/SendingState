//
//  TestAutoReleasable.swift
//  SendingState
//
//  Created by SunSoo Jeon on 23.06.2023.
//

@testable import SendingState

final class TestAutoReleasable: AutoReleasable {
    var ownerIdentifier: ObjectIdentifier?

    static var instanceCount = 0
    static var cleanupCallCount = 0

    let id: Int
    var cleanupCalled = false

    init(id: Int) {
        self.id = id
        Self.instanceCount += 1
    }

    deinit {
        Self.instanceCount -= 1
    }

    func cleanup() {
        cleanupCalled = true
        Self.cleanupCallCount += 1
    }

    static func resetCounters() {
        instanceCount = 0
        cleanupCallCount = 0
    }
}
