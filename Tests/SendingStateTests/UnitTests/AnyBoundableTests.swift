//
//  AnyBoundableTests.swift
//  SendingState
//
//  Created by SunSoo Jeon on 23.06.2023.
//

import XCTest
@testable import SendingState

final class AnyBoundableTests: XCTestCase {}

#if os(iOS) || targetEnvironment(macCatalyst)
import UIKit

@MainActor
extension AnyBoundableTests {
    // MARK: - Hashable

    func test_any_boundable_hashable() {
        // Given
        let model = TestConfigurableUIView.Model(text: "Test", value: 11)

        // When
        let anyBoundable1 = TestBoundableViewModel(contentData: model).eraseToAnyBoundable()
        let anyBoundable2 = TestBoundableViewModel(contentData: model).eraseToAnyBoundable()

        // Then
        XCTAssertNotEqual(anyBoundable1, anyBoundable2)

        let set: Set<AnyBoundable> = [anyBoundable1, anyBoundable2]
        XCTAssertEqual(set.count, 2)
    }

    func test_any_boundable_as_dictionary_key() {
        // Given
        let model = TestConfigurableUIView.Model(text: "Test", value: 11)
        let anyBoundable = TestBoundableViewModel(contentData: model).eraseToAnyBoundable()
        var dict: [AnyBoundable: String] = [:]

        // When
        dict[anyBoundable] = "value"

        // Then
        XCTAssertEqual(dict[anyBoundable], "value")
    }

    func test_any_boundable_equality_by_uuid() {
        // Given
        let boundable = TestBoundableViewModel(
            contentData: TestConfigurableUIView.Model(text: "Test", value: 11)
        )

        // When
        let anyBoundable = boundable.eraseToAnyBoundable()
        let otherAnyBoundable = boundable.eraseToAnyBoundable()

        // Then
        XCTAssertNotEqual(anyBoundable, otherAnyBoundable)
    }

    // MARK: - ContentData Access

    func test_content_data_type_erased() {
        // Given
        let model = TestConfigurableUIView.Model(text: "Original", value: 34)

        // When
        let anyBoundable = TestBoundableViewModel(contentData: model).eraseToAnyBoundable()

        // Then
        XCTAssertNotNil(anyBoundable.contentData)

        if let data = anyBoundable.contentData as? TestConfigurableUIView.Model {
            XCTAssertEqual(data.text, "Original")
            XCTAssertEqual(data.value, 34)
        } else {
            XCTFail("Failed to cast content data")
        }
    }

    func test_content_data_nil() {
        // Given
        let boundable = TestBoundableViewModel(contentData: nil)

        // When
        let anyBoundable = boundable.eraseToAnyBoundable()

        // Then
        XCTAssertNil(anyBoundable.contentData)
    }

    // MARK: - BinderType Access

    func test_binder_type_preserved() {
        // Given
        let boundable = TestBoundableViewModel(
            contentData: TestConfigurableUIView.Model(text: "Test", value: 11)
        )

        // When
        let anyBoundable = boundable.eraseToAnyBoundable()

        // Then
        XCTAssertTrue(anyBoundable.binderType == TestConfigurableUIView.self)
    }

    // MARK: - Bound Method

    func test_apply_with_correct_type() {
        // Given
        let model = TestConfigurableUIView.Model(text: "Boundable", value: 1)
        let anyBoundable = TestBoundableViewModel(contentData: model).eraseToAnyBoundable()
        let view = TestConfigurableUIView()

        // When
        anyBoundable.apply(to: view)

        // Then
        XCTAssertEqual(view.lastModel, model)
    }

    func test_apply_with_wrong_type_ignored() {
        class OtherView: UIView, Configurable {
            struct Model { let text: String; let value: Int }

            var didRunConfigurer = false

            var configurer: (OtherView, Model) -> Void {
                { view, _ in view.didRunConfigurer = true }
            }
        }

        // Given
        let model = TestConfigurableUIView.Model(text: "zzz", value: 4)
        let anyBoundable = TestBoundableViewModel(contentData: model).eraseToAnyBoundable()
        let wrongView = OtherView()

        // When
        anyBoundable.apply(to: wrongView)

        // Then
        XCTAssertFalse(wrongView.didRunConfigurer, "Apply should do nothing when view type doesn't match binderType")
    }

    // MARK: - Size Method

    func test_size_with_valid_data() {
        class SizableView: UIView, Configurable {
            struct Model {
                let lines: Int
            }

            var configurer: (SizableView, Model) -> Void {
                { _, _ in }
            }

            nonisolated static func size(
                with input: Model?,
                constrainedTo parentSize: CGSize?
            ) -> CGSize? {
                guard let input = input else { return nil }
                let height = CGFloat(input.lines * 20)
                return CGSize(width: parentSize?.width ?? 100, height: height)
            }
        }

        struct SizableBoundable: Boundable {
            var contentData: SizableView.Model?
            var binderType: SizableView.Type { SizableView.self }
        }

        // Given
        let model = SizableView.Model(lines: 5)
        let anyBoundable = SizableBoundable(contentData: model).eraseToAnyBoundable()

        // When
        let size = anyBoundable.size(constrainedTo: CGSize(width: 200, height: 500))

        // Then
        XCTAssertNotNil(size)

        if let size = size {
            XCTAssertEqual(size.width, 200)
            XCTAssertEqual(size.height, 100) // 5 * 20
        }
    }

    func test_size_with_nil_data_returns_nil() {
        // Given
        let anyBoundable = TestBoundableViewModel(contentData: nil).eraseToAnyBoundable()

        // When
        let size = anyBoundable.size(constrainedTo: CGSize(width: 320, height: 100))

        // Then
        XCTAssertNil(size)
    }

    func test_any_boundable_size_with_default_implementation() {
        // Given
        let model = TestConfigurableUIView.Model(text: "Test", value: 11)
        let anyBoundable = TestBoundableViewModel(contentData: model).eraseToAnyBoundable()

        // When
        let size = anyBoundable.size(constrainedTo: CGSize(width: 375, height: 300))

        // Then
        XCTAssertNil(size)
    }

    // MARK: - Identifier Preservation

    func test_any_boundable_preserves_identifier() {
        struct IdentifiableBoundable: Boundable {
            var contentData: TestConfigurableUIView.Model?
            var binderType: TestConfigurableUIView.Type { TestConfigurableUIView.self }
            var identifier: String? { "4323" }
        }

        // Given
        let boundable = IdentifiableBoundable(
            contentData: TestConfigurableUIView.Model(text: "2333", value: 22)
        )

        // When
        let anyBoundable = boundable.eraseToAnyBoundable()

        // Then
        XCTAssertEqual(anyBoundable.identifier, "4323")
    }

    // MARK: - Collection Operations

    func test_filter_boundables_by_identifier() {
        struct IdentifiedBoundable: Boundable {
            var contentData: TestConfigurableUIView.Model?
            var binderType: TestConfigurableUIView.Type { TestConfigurableUIView.self }
            var identifier: String?
        }

        // Given
        let anyBoundables: [AnyBoundable] = [
            IdentifiedBoundable(
                contentData: TestConfigurableUIView.Model(text: "Pizza", value: 1),
                identifier: "Food"
            ).eraseToAnyBoundable(),
            IdentifiedBoundable(
                contentData: TestConfigurableUIView.Model(text: "Beer", value: 2),
                identifier: "Drink"
            ).eraseToAnyBoundable(),
            IdentifiedBoundable(
                contentData: TestConfigurableUIView.Model(text: "Kimchi", value: 3),
                identifier: "Food"
            ).eraseToAnyBoundable()
        ]

        // When
        let filtered = anyBoundables.filter { $0.identifier == "Food" }

        // Then
        XCTAssertEqual(filtered.count, 2)
    }

    func test_map_boundables_to_views() {
        // Given
        let models = (0..<5).map { i in
            TestConfigurableUIView.Model(text: "TestItem\(i)", value: i)
        }
        let anyBoundable = models.map { model in
            TestBoundableViewModel(contentData: model).eraseToAnyBoundable()
        }
        let views = anyBoundable.map { _ in TestConfigurableUIView() }

        // When
        for (boundable, view) in zip(anyBoundable, views) {
            boundable.apply(to: view)
        }

        // Then
        XCTAssertEqual(views.count, 5)
        XCTAssertEqual(views[0].lastModel?.text, "TestItem0")
        XCTAssertEqual(views[4].lastModel?.text, "TestItem4")
    }

    // MARK: - Memory Management

    func test_any_boundable_binding_works() {
        // Given
        let view = TestConfigurableUIView()
        let anyBoundable = TestBoundableViewModel(
            contentData: TestConfigurableUIView.Model(text: "Test", value: 56)
        ).eraseToAnyBoundable()

        // When
        anyBoundable.apply(to: view)

        // Then
        XCTAssertEqual(view.lastModel?.text, "Test")
        XCTAssertEqual(view.lastModel?.value, 56)
    }
}
#endif
