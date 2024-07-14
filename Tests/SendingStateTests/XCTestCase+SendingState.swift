//
//  XCTestCase+SendingState.swift
//  SendingState
//
//  Created by SunSoo Jeon on 26.06.2023.
//

import XCTest

extension XCTestCase {
    /// Waits until a condition is met or timeout occurs
    func waitUntil(
        timeout: TimeInterval = 1.0,
        description: String = "Waiting for condition",
        _ condition: @escaping () -> Bool
    ) {
        let expectation = XCTestExpectation(description: description)

        let timer = Timer.scheduledTimer(
            withTimeInterval: 0.01,
            repeats: true
        ) { timer in
            if condition() {
                expectation.fulfill()
                timer.invalidate()
            }
        }

        let result = XCTWaiter.wait(for: [expectation], timeout: timeout)
        timer.invalidate()

        if result == .timedOut {
            XCTFail("Condition not met within \(timeout) seconds")
        }
    }
}
