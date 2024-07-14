//
//  PresentableTests.swift
//  SendingState
//
//  Created by SunSoo Jeon on 02.11.2022.
//

import XCTest
@testable import SendingState

@MainActor
final class PresentableTests: XCTestCase {
    func test_apply_sets_binder_with_current_state() {
        // Given
        let presentable = TestPresentable(state: 11)
        let binder = TestPresentable.Binder()

        // When
        presentable.apply(to: binder)

        // Then
        XCTAssertEqual(binder.lastConfigured, 11)
    }
    
    func test_state_mutation_then_apply() {
        // Given
        var presentable = TestPresentable(state: 30)
        let binder = TestPresentable.Binder()

        // When
        presentable.state = 90
        presentable.apply(to: binder)

        // Then
        XCTAssertEqual(binder.lastConfigured, 90)
    }
}
