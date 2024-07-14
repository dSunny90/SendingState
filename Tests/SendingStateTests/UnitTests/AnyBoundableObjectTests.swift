//
//  AnyBoundableObjectTests.swift
//  SendingState
//
//  Created by SunSoo Jeon on 23.06.2023.
//

import XCTest
@testable import SendingState

final class AnyBoundableObjectTests: XCTestCase {}

#if os(iOS) || targetEnvironment(macCatalyst)
import UIKit

private struct TestProtocolBoundableViewModel: Boundable {
    var contentData: TestProtocolConfigurableUIView.Model?
    var binderType: TestProtocolConfigurableUIView.Type { TestProtocolConfigurableUIView.self }
}

@MainActor
extension AnyBoundableObjectTests {
    // MARK: - Subclass Apply

    func test_subclass_apply_to_view() {
        // Given
        let model = TestProtocolConfigurableUIView.Model(title: "Hello", count: 5)
        let vm = TestProtocolBoundableViewModel(contentData: model)
        let obj = TestTypedBoundableObject(vm)
        let view = TestProtocolConfigurableUIView()

        // When
        obj.apply(to: view)
        obj.testMethod(to: view)

        // Then
        XCTAssertEqual(view.lastModel, model)
        XCTAssertEqual(view.configureCallCount, 1)
        XCTAssertEqual(view.updatedCount, 5)
    }

    func test_subclass_apply_with_nil_content() {
        // Given
        let vm = TestProtocolBoundableViewModel(contentData: nil)
        let obj = TestTypedBoundableObject(vm)
        let view = TestProtocolConfigurableUIView()

        // When
        XCTAssertNoThrow(
            obj.apply(to: view)
        )

        // Then
        XCTAssertEqual(view.configureCallCount, 0)
        XCTAssertNil(view.lastModel)
    }

    // MARK: - Content Data Preservation

    func test_subclass_preserves_content_data() {
        // Given
        let model = TestProtocolConfigurableUIView.Model(title: "Swift", count: 10)
        let vm = TestProtocolBoundableViewModel(contentData: model)

        // When
        let obj = TestTypedBoundableObject(vm)

        // Then
        XCTAssertNotNil(obj.contentData)

        if let data = obj.contentData as? TestProtocolConfigurableUIView.Model {
            XCTAssertEqual(data.title, "Swift")
            XCTAssertEqual(data.count, 10)
        } else {
            XCTFail("Failed to cast content data")
        }
    }

    // MARK: - Binder Type Preservation

    func test_subclass_preserves_binder_type() {
        // Given
        let vm = TestProtocolBoundableViewModel(
            contentData: TestProtocolConfigurableUIView.Model(title: "World", count: 1)
        )

        // When
        let obj = TestTypedBoundableObject(vm)

        // Then
        XCTAssertTrue(obj.binderType == TestProtocolConfigurableUIView.self)
    }

    // MARK: - Hashable

    func test_subclass_hashable() {
        // Given
        let model = TestProtocolConfigurableUIView.Model(title: "SendingState", count: 7)

        // When
        let obj1 = TestTypedBoundableObject(TestProtocolBoundableViewModel(contentData: model))
        let obj2 = TestTypedBoundableObject(TestProtocolBoundableViewModel(contentData: model))

        // Then
        XCTAssertNotEqual(obj1, obj2)

        let set: Set<AnyBoundableObject> = [obj1, obj2]
        XCTAssertEqual(set.count, 2)
    }

    // MARK: - Wrong View Type

    func test_subclass_apply_with_wrong_view_type_ignored() {
        class OtherView: UIView, Configurable {
            struct Model { let text: String }

            var didRunConfigurer = false

            var configurer: (OtherView, Model) -> Void {
                { view, _ in view.didRunConfigurer = true }
            }
        }

        // Given
        let model = TestProtocolConfigurableUIView.Model(title: "Test", count: 0)
        let obj = TestTypedBoundableObject(TestProtocolBoundableViewModel(contentData: model))
        let wrongView = OtherView()

        // When
        obj.apply(to: wrongView)

        // Then
        XCTAssertFalse(
            wrongView.didRunConfigurer,
            "Apply should do nothing when view type doesn't match binderType"
        )
    }

    // MARK: - Heterogeneous Collection

    func test_subclass_in_heterogeneous_collection() {
        // Given
        let models = (0..<3).map { i in
            TestProtocolConfigurableUIView.Model(title: "Item \(i)", count: i)
        }
        let objects: [AnyBoundableObject] = models.map { model in
            TestTypedBoundableObject(TestProtocolBoundableViewModel(contentData: model))
        }
        let views = (0..<3).map { _ in TestProtocolConfigurableUIView() }

        // When
        for (obj, view) in zip(objects, views) {
            obj.apply(to: view)
        }

        // Then
        XCTAssertEqual(views[0].lastModel?.title, "Item 0")
        XCTAssertEqual(views[1].lastModel?.title, "Item 1")
        XCTAssertEqual(views[2].lastModel?.title, "Item 2")
        XCTAssertEqual(views[0].lastModel?.count, 0)
        XCTAssertEqual(views[1].lastModel?.count, 1)
        XCTAssertEqual(views[2].lastModel?.count, 2)
    }
}
#endif
