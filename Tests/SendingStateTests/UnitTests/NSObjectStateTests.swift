//
//  NSObjectStateTests.swift
//  SendingState
//
//  Created by SunSoo Jeon on 23.06.2023.
//

import XCTest
@testable import SendingState

#if os(iOS) || targetEnvironment(macCatalyst)
import UIKit

final class NSObjectStateTests: XCTestCase {
    // MARK: - Basic state() / removeState()

    @MainActor
    func test_state_returns_nil_when_nothing_stored() {
        // Given
        let button = TestFixture.makeButton()

        // Then
        let result: String? = button.ss.state()
        XCTAssertNil(result)
    }

    @MainActor
    func test_state_returns_struct_value_stored_via_configure() {
        // Given
        let view = TestConfigurableUIView()
        let model = TestConfigurableUIView.Model(text: "Hello, SendingState!", value: 815)

        // When
        view.ss.configure(model)

        // Then — Configurable & NSObject overload: no type annotation needed
        let result = view.ss.state()
        XCTAssertEqual(result, model)
    }

    @MainActor
    func test_state_returns_nil_for_type_mismatch() {
        // Given
        let view = TestConfigurableUIView()
        view.ss.configure(TestConfigurableUIView.Model(text: "I am nil.", value: 1111))

        // When — try to read as String
        let result: String? = view.ss.state()

        // Then
        XCTAssertNil(result)
    }

    @MainActor
    func test_removeState_clears_stored_value() {
        // Given
        let view = TestConfigurableUIView()
        view.ss.configure(TestConfigurableUIView.Model(text: "I am here."))

        // When
        view.ss.removeState()

        // Then
        let result = view.ss.state()
        XCTAssertNil(result)
    }

    // MARK: - configure() → configurer auto-call

    @MainActor
    func test_configure_calls_configurer() {
        // Given
        let view = TestConfigurableUIView()
        XCTAssertEqual(view.configureCallCount, 0)

        // When
        view.ss.configure(TestConfigurableUIView.Model(text: "TestModel"))

        // Then
        XCTAssertEqual(view.configureCallCount, 1)
        XCTAssertEqual(view.lastModel?.text, "TestModel")
    }

    @MainActor
    func test_configure_again_calls_configurer_again() {
        // Given
        let view = TestConfigurableUIView()
        view.ss.configure(TestConfigurableUIView.Model(text: "Alpha"))

        // When
        view.ss.configure(TestConfigurableUIView.Model(text: "Beta"))

        // Then
        XCTAssertEqual(view.configureCallCount, 2)
        XCTAssertEqual(view.lastModel?.text, "Beta")
    }

    @MainActor
    func test_configure_updates_state_each_time() {
        // Given
        let view = TestConfigurableUIView()

        // When
        view.ss.configure(TestConfigurableUIView.Model(text: "But", value: 11))
        view.ss.configure(TestConfigurableUIView.Model(text: "So", value: 8))

        // Then — state reflects the latest
        let state = view.ss.state()
        XCTAssertEqual(state, TestConfigurableUIView.Model(text: "So", value: 8))
    }

    // MARK: - configure() → sender propagation

    @MainActor
    func test_configure_propagates_state_to_senders() {
        // Given
        let cell = TestStateUIView()
        let model = TestConfigurableUIView.Model(text: "Model", value: 30)

        // When
        cell.ss.configure(model)

        // Then — sender (button) should have the state
        let senderState: TestConfigurableUIView.Model? = cell.button.ss.state()
        XCTAssertEqual(senderState, model)
    }

    @MainActor
    func test_configure_propagates_to_all_senders() {
        // Given
        let cell = TestStateMultiSenderUIView()
        let model = TestConfigurableUIView.Model(text: "Data", value: 90)

        // When
        cell.ss.configure(model)

        // Then — both senders should have the state
        let buttonState: TestConfigurableUIView.Model? = cell.button.ss.state()
        let switchState: TestConfigurableUIView.Model? = cell.toggle.ss.state()
        XCTAssertEqual(buttonState, model)
        XCTAssertEqual(switchState, model)
    }

    @MainActor
    func test_reconfigure_updates_sender_state() {
        // Given
        let cell = TestStateUIView()
        cell.ss.configure(TestConfigurableUIView.Model(text: "Sun"))

        // When
        cell.ss.configure(TestConfigurableUIView.Model(text: "Moon"))

        // Then
        let senderState: TestConfigurableUIView.Model? = cell.button.ss.state()
        XCTAssertEqual(senderState?.text, "Moon")
    }

    // MARK: - Boundable.apply(to:) → state + configurer + sender

    @MainActor
    func test_apply_stores_state_and_calls_configurer() {
        // Given
        let cell = TestConfigurableUIView()
        let model = TestConfigurableUIView.Model(text: "Hello", value: 90)
        let vm = TestBoundableViewModel(contentData: model)

        // When
        vm.apply(to: cell)

        // Then — configurer called
        XCTAssertEqual(cell.configureCallCount, 1)
        XCTAssertEqual(cell.lastModel, model)

        // Then — state stored (Configurable overload: no type annotation)
        let state = cell.ss.state()
        XCTAssertEqual(state, model)
    }

    @MainActor
    func test_apply_propagates_to_senders() {
        // Given
        let cell = TestStateUIView()
        let model = TestConfigurableUIView.Model(text: "Swift", value: 37)
        let vm = TestStateViewModel(contentData: model)

        // When
        vm.apply(to: cell)

        // Then
        let senderState: TestConfigurableUIView.Model? = cell.button.ss.state()
        XCTAssertEqual(senderState, model)
    }

    // MARK: - AnyBoundable.apply(to:) → observer route

    @MainActor
    func test_anyBoundable_apply_routes_through_observer() {
        // Given
        let cell = TestConfigurableUIView()
        let model = TestConfigurableUIView.Model(text: "World", value: 13)
        let vm = TestBoundableViewModel(contentData: model)
        let anyBoundable = vm.eraseToAnyBoundable()

        // When
        anyBoundable.apply(to: cell)

        // Then — configurer called
        XCTAssertEqual(cell.configureCallCount, 1)
        XCTAssertEqual(cell.lastModel, model)

        // Then — state stored (Configurable overload: no type annotation)
        let state = cell.ss.state()
        XCTAssertEqual(state, model)
    }

    // MARK: - Cell reuse (overwrite)

    @MainActor
    func test_cell_reuse_overwrites_previous_state() {
        // Given
        let cell = TestStateUIView()
        cell.ss.configure(TestConfigurableUIView.Model(text: "Hi"))

        // When — simulating cell reuse with different data
        cell.ss.configure(TestConfigurableUIView.Model(text: "Bye"))

        // Then — cell state is latest (Configurable overload)
        let cellState = cell.ss.state()
        XCTAssertEqual(cellState?.text, "Bye")

        // Then — sender state is also latest (generic overload: type required)
        let senderState: TestConfigurableUIView.Model? = cell.button.ss.state()
        XCTAssertEqual(senderState?.text, "Bye")
    }

    // MARK: - Non-NSObject Configurable (fallback)

    @MainActor
    func test_configure_non_NSObject_calls_configurer_directly() {
        // Given
        let obj = TestConfigurableObject()

        // When — TestConfigurableObject is not SendingStateHost,
        // so we construct SendingState directly (same as AnyBoundable does).
        SendingState(obj).configure("안녕")

        // Then — configurer called
        XCTAssertEqual(obj.inputValue, "안녕")
    }

    // MARK: - State independence per object

    @MainActor
    func test_state_is_independent_per_object() {
        // Given
        let view1 = TestConfigurableUIView()
        let view2 = TestConfigurableUIView()

        // When
        view1.ss.configure(TestConfigurableUIView.Model(text: "Go"))
        view2.ss.configure(TestConfigurableUIView.Model(text: "Rust"))

        // Then (Configurable overload: no type annotation)
        let state1 = view1.ss.state()
        let state2 = view2.ss.state()
        XCTAssertEqual(state1?.text, "Go")
        XCTAssertEqual(state2?.text, "Rust")
    }

    // MARK: - Class input (deinit)

    @MainActor
    func test_class_input_deinit_called_on_state_overwrite() {
        // Given
        let view = TestClassInputConfigurableUIView()
        var deinitCalled = false

        autoreleasepool {
            let input = DeinitTracker { deinitCalled = true }
            view.ss.configure(input)
        }
        // local `input` is released but observer + boundState retain it
        XCTAssertFalse(deinitCalled)

        // When — overwrite with new input
        autoreleasepool {
            let input2 = DeinitTracker {}
            view.ss.configure(input2)
        }

        // Then — old input should be released
        XCTAssertTrue(deinitCalled)
    }

    @MainActor
    func test_class_input_deinit_called_on_removeState() {
        // Given
        let view = TestClassInputConfigurableUIView()
        var deinitCalled = false

        autoreleasepool {
            let input = DeinitTracker { deinitCalled = true }
            view.ss.configure(input)
        }
        // local `input` is released but observer + boundState retain it
        XCTAssertFalse(deinitCalled)

        // When
        view.ss.removeState()

        // Then
        XCTAssertTrue(deinitCalled)
    }

    // MARK: - Dealloc cleanup

    @MainActor
    func test_state_released_when_object_deallocated() {
        // Given
        weak var weakRef: DeinitTracker?
        autoreleasepool {
            let view = TestClassInputConfigurableUIView()
            let input = DeinitTracker {}
            weakRef = input
            view.ss.configure(input)
            XCTAssertNotNil(weakRef)
        }

        // Then — input released with view
        XCTAssertNil(weakRef)
    }

    @MainActor
    func test_stateObserver_released_when_object_deallocated() {
        // Given
        weak var weakObserver: StateObserver?
        autoreleasepool {
            let view = TestConfigurableUIView()
            view.ss.configure(TestConfigurableUIView.Model(text: "TempModel"))
            weakObserver = view.stateObserver
            XCTAssertNotNil(weakObserver)
        }

        // Then — observer released with view
        XCTAssertNil(weakObserver)
    }

    @MainActor
    func test_observer_does_not_call_configurer_after_binder_dealloc() {
        // Given
        var callCount = 0
        var observer: StateObserver?
        autoreleasepool {
            let view = TestClosureConfigurableUIView { callCount += 1 }
            view.ss.configure("TempModel")
            observer = view.stateObserver
            XCTAssertEqual(callCount, 1)
        }
        // binder is deallocated

        // When — manually trigger (should be no-op, binder is nil)
        observer?.update("NewModel")

        // Then — configurer not called again
        XCTAssertEqual(callCount, 1)
    }

    // MARK: - Sender state after direct boundState set

    @MainActor
    func test_boundState_on_button_accessible_via_ss_state() {
        // Given
        let button = TestFixture.makeButton()

        // When
        button.boundState = "since1990"

        // Then
        let result: String? = button.ss.state()
        XCTAssertEqual(result, "since1990")
    }
}

#endif
