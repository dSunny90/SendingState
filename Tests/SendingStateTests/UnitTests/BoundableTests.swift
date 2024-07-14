//
//  BoundableTests.swift
//  SendingState
//
//  Created by SunSoo Jeon on 23.06.2023.
//

import XCTest
@testable import SendingState

final class BoundableTests: XCTestCase {
    @MainActor
    func test_boundable_configures_binder() {
        // Given
        let model = TestBoundableModel(contentData: "Hello, World!")
        let obj = TestConfigurableObject()

        // When
        model.apply(to: obj)

        // Then
        XCTAssertEqual(obj.inputValue, "Hello, World!")
    }
}

#if os(iOS) || targetEnvironment(macCatalyst)
import UIKit

@MainActor
extension BoundableTests {
    // MARK: - Nil Content Data

    func test_apply_with_nil_content_data() {
        // Given
        let view = TestConfigurableUIView()
        let boundable = TestBoundableViewModel(contentData: nil)

        // When
        XCTAssertNoThrow(
            boundable.apply(to: view)
        )

        // Then
        XCTAssertEqual(view.configureCallCount, 0)
    }

    func test_apply_with_optional_model() {
        struct OptionalBoundable: Boundable {
            var contentData: TestConfigurableUIView.Model?
            var binderType: TestConfigurableUIView.Type { TestConfigurableUIView.self }
        }

        // Given
        let view = TestConfigurableUIView()
        let boundable = OptionalBoundable(contentData: nil)

        // When
        boundable.apply(to: view)

        // Then
        XCTAssertEqual(view.configureCallCount, 0)
    }

    // MARK: - Type Erasure

    func test_erase_to_any_boundable() {
        // Given
        let model = TestConfigurableUIView.Model(text: "Test", value: 11)
        let boundable = TestBoundableViewModel(contentData: model)

        // When
        let anyBoundable = boundable.eraseToAnyBoundable()

        // Then
        XCTAssertTrue(ObjectIdentifier(anyBoundable.binderType) == ObjectIdentifier(TestConfigurableUIView.self))
        XCTAssertNotNil(anyBoundable.contentData)
    }

    // MARK: - Heterogeneous Collection

    func test_heterogeneous_boundable_collection() {
        struct Model1 {
            let value: Int
        }

        struct Model2 {
            let text: String
        }

        class View1: UIView, Configurable {
            var configurer: (View1, Model1) -> Void {
                { _, _ in }
            }
        }

        class View2: UIView, Configurable {
            var configurer: (View2, Model2) -> Void {
                { _, _ in }
            }
        }

        struct Boundable1: Boundable {
            var contentData: Model1?
            var binderType: View1.Type { View1.self }
        }

        struct Boundable2: Boundable {
            var contentData: Model2?
            var binderType: View2.Type { View2.self }
        }

        // Given
        let model1 = Model1(value: 11)
        let model2 = Model2(text: "Test")

        // When
        let boundables: [AnyBoundable] = [
            Boundable1(contentData: model1).eraseToAnyBoundable(),
            Boundable2(contentData: model2).eraseToAnyBoundable()
        ]

        // Then
        XCTAssertEqual(boundables.count, 2)
    }

    // MARK: - Identifier

    func test_boundable_default_identifier_is_nil() {
        // Given
        let optionalModel: TestConfigurableUIView.Model? = nil

        // When
        let boundable = TestBoundableViewModel(contentData: optionalModel)

        // Then
        XCTAssertNil(boundable.identifier)
    }

    func test_boundable_custom_identifier() {
        struct IdentifiableBoundable: Boundable {
            var contentData: TestConfigurableUIView.Model?
            var binderType: TestConfigurableUIView.Type { TestConfigurableUIView.self }
            var identifier: String? { "Sunny" }
        }

        // Given
        let model = TestConfigurableUIView.Model(text: "Test", value: 11)

        // When
        let boundable = IdentifiableBoundable(contentData: model)

        // Then
        XCTAssertEqual(boundable.identifier, "Sunny")
    }

    // MARK: - Multiple Bindings

    func test_apply_same_model_to_multiple_views() {
        // Given
        let model = TestConfigurableUIView.Model(text: "Test", value: 11)
        let boundable = TestBoundableViewModel(contentData: model)

        let view1 = TestConfigurableUIView()
        let view2 = TestConfigurableUIView()
        let view3 = TestConfigurableUIView()

        // When
        boundable.apply(to: view1)
        boundable.apply(to: view2)
        boundable.apply(to: view3)

        // Then
        XCTAssertEqual(view1.lastModel, model)
        XCTAssertEqual(view2.lastModel, model)
        XCTAssertEqual(view3.lastModel, model)
    }

    func test_apply_after_content_change() {
        // Given
        struct MutableBoundable: Boundable {
            var contentData: TestConfigurableUIView.Model?
            var binderType: TestConfigurableUIView.Type { TestConfigurableUIView.self }
        }

        var boundable = MutableBoundable(
            contentData: TestConfigurableUIView.Model(text: "Sunny", value: 11)
        )
        let view = TestConfigurableUIView()

        // When
        boundable.apply(to: view)

        // Then
        XCTAssertEqual(view.lastModel?.text, "Sunny")

        // When
        boundable.contentData = TestConfigurableUIView.Model(text: "Jeon", value: 30)
        boundable.apply(to: view)

        // Then
        XCTAssertEqual(view.lastModel?.text, "Jeon")
    }

    // MARK: - Sendable Conformance

    func test_boundable_sendable_across_threads() {
        struct SendableBoundable: Boundable {
            var contentData: TestConfigurableUIView.Model?
            var binderType: TestConfigurableUIView.Type { TestConfigurableUIView.self }
        }

        // Given
        let model = TestConfigurableUIView.Model(text: "Concurrent", value: 432)
        let boundable = SendableBoundable(contentData: model)

        // When
        let expectation = XCTestExpectation(description: "Cross-thread binding")

        DispatchQueue.global().async {
            Task { @MainActor in
                let view = TestConfigurableUIView()
                boundable.apply(to: view)

                // Then
                XCTAssertEqual(view.lastModel?.text, "Concurrent")
                XCTAssertEqual(view.lastModel?.value, 432)
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 2.0)
    }

    // MARK: - Array of Boundables

    func test_array_of_boundables_applying() {
        // Given
        let models = [
            TestConfigurableUIView.Model(text: "Swift", value: 1),
            TestConfigurableUIView.Model(text: "Objective-C", value: 2),
            TestConfigurableUIView.Model(text: "Python", value: 3)
        ]

        let boundables = models.map { TestBoundableViewModel(contentData: $0) }
        let views = [
            TestConfigurableUIView(),
            TestConfigurableUIView(),
            TestConfigurableUIView()
        ]

        // When
        for (boundable, view) in zip(boundables, views) {
            boundable.apply(to: view)
        }

        // Then
        XCTAssertEqual(views[0].lastModel?.text, "Swift")
        XCTAssertEqual(views[1].lastModel?.text, "Objective-C")
        XCTAssertEqual(views[2].lastModel?.text, "Python")
    }

    func test_concurrent_boundable_operations() async {
        // Given
        let views = (0..<10).map { _ in TestConfigurableUIView() }
        let models = (0..<10).map { i in
            TestConfigurableUIView.Model(text: "Item\(i)", value: i)
        }

        // When
        await withTaskGroup(of: Void.self) { group in
            for (view, model) in zip(views, models) {
                group.addTask { @MainActor in
                    let boundable = TestBoundableViewModel(contentData: model)
                    boundable.apply(to: view)
                }
            }
        }

        // Then
        for (index, view) in views.enumerated() {
            XCTAssertEqual(view.lastModel?.value, index)
        }
    }
}
#endif
