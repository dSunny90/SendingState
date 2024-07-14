//
//  ConfigurableTests.swift
//  SendingState
//
//  Created by SunSoo Jeon on 23.06.2023.
//

import XCTest
@testable import SendingState

@MainActor
final class ConfigurableTests: XCTestCase {
    func test_configurer_applies_model_value() {
        // Given
        let obj = TestConfigurableObject()

        // When
        obj.configurer(obj, "Hello, World!")

        // Then
        XCTAssertEqual(obj.inputValue, "Hello, World!")
    }
}

#if os(iOS) || targetEnvironment(macCatalyst)
import UIKit

@MainActor
extension ConfigurableTests {
    // MARK: - Nil Input Handling

    func test_configure_with_optional_nil_input() {
        class OptionalConfigurableView: UIView, Configurable {
            var lastModel: String?
            var configureCount = 0

            var configurer: (OptionalConfigurableView, String?) -> Void {
                { view, model in
                    view.configureCount += 1
                    view.lastModel = model
                }
            }
        }
        // Given
        let view = OptionalConfigurableView()

        // When
        view.ss.configure(nil as String?)

        // Then
        XCTAssertEqual(view.configureCount, 1)
        XCTAssertNil(view.lastModel)
    }

    // MARK: - Multiple Configurations

    func test_configure_called_multiple_times() {
        // Given
        let view = TestConfigurableUIView()
        let model1 = TestConfigurableUIView.Model(text: "안녕하세요", value: 1)
        let model2 = TestConfigurableUIView.Model(text: "Hi", value: 2)
        let model3 = TestConfigurableUIView.Model(text: "Bonjour", value: 3)

        // When
        view.ss.configure(model1)
        view.ss.configure(model2)
        view.ss.configure(model3)

        // Then
        XCTAssertEqual(view.configureCallCount, 3)
        XCTAssertEqual(view.lastModel, model3)
    }

    func test_rapid_consecutive_configurations() {
        // Given
        let view = TestConfigurableUIView()
        let testCount: Int = 100

        // When
        for i in 0..<testCount {
            let model = TestConfigurableUIView.Model(text: "Text_\(i)", value: i+1)
            view.ss.configure(model)
        }

        // Then
        XCTAssertEqual(view.configureCallCount, testCount)
        XCTAssertEqual(view.lastModel?.value, testCount)
    }

    // MARK: - Size Calculation

    func test_size_with_nil_input() {
        // Given
        let optionalModel: TestConfigurableUIView.Model? = nil
        let parentSize: CGSize = CGSize(width: 375, height: 375)

        // When
        let size = TestConfigurableUIView.size(
            with: optionalModel,
            constrainedTo: parentSize
        )

        // Then
        XCTAssertNil(size)
    }

    func test_size_with_nil_constraint() {
        // Given
        let model = TestConfigurableUIView.Model(text: "Test", value: 11)
        let parentSize: CGSize? = nil

        // When
        let size = TestConfigurableUIView.size(
            with: model,
            constrainedTo: parentSize
        )

        // Then
        XCTAssertNil(size)
    }

    func test_size_with_both_nil() {
        // Given
        let optionalModel: TestConfigurableUIView.Model? = nil
        let parentSize: CGSize? = nil

        // When
        let size = TestConfigurableUIView.size(
            with: optionalModel,
            constrainedTo: parentSize
        )

        // Then
        XCTAssertNil(size)
    }

    // MARK: - Custom Size Implementation

    func test_custom_size_calculation() {
        class SizableView: UIView, Configurable {
            struct Model {
                let itemCount: Int
            }

            var configurer: (SizableView, Model) -> Void {
                { view, model in
                    // Configure
                }
            }

            nonisolated static func size(
                with input: Model?,
                constrainedTo parentSize: CGSize?
            ) -> CGSize? {
                guard let input = input else { return nil }

                let width = parentSize?.width ?? 375
                let height = CGFloat(input.itemCount * 30) // 30pt per item

                return CGSize(width: width, height: height)
            }
        }

        // Given
        let model = SizableView.Model(itemCount: 8)
        let constraint = CGSize(width: 414, height: 300)

        // When
        let size = SizableView.size(with: model, constrainedTo: constraint)

        // Then
        XCTAssertEqual(size?.width, 414)
        XCTAssertEqual(size?.height, 240) // 8 * 30
    }

    func test_size_with_long_text() {
        class LabelView: UIView, Configurable {
            struct Model {
                let text: String
                let fontSize: CGFloat
            }

            var configurer: (LabelView, Model) -> Void {
                { _, _ in }
            }

            nonisolated static func size(
                with input: Model?,
                constrainedTo parentSize: CGSize?
            ) -> CGSize? {
                guard let input else { return nil }
                let width = parentSize?.width ?? 100
                let height = input.text.count > 10 ? 60 : 40
                return CGSize(width: width, height: CGFloat(height))
            }
        }

        // Given
        let model = LabelView.Model(text: "This is a very long string", fontSize: 14)

        // When
        let size = LabelView.size(with: model, constrainedTo: .init(width: 150, height: 200))

        // Then
        XCTAssertEqual(size?.height, 60)
    }

    // MARK: - Configurer Closure Behavior

    func test_configurer_applies_model() {
        // Given
        let view = TestConfigurableUIView()
        let model = TestConfigurableUIView.Model(text: "Test", value: 1)

        // When
        view.ss.configure(model)

        // Then
        XCTAssertEqual(view.lastModel?.text, "Test")
        XCTAssertEqual(view.lastModel?.value, 1)
    }

    // MARK: - Synchronous Configurer Pattern

    func test_configure_updates_synchronously() {
        class LabelView: UIView, Configurable {
            struct Model {
                let text: String
                let fontSize: CGFloat
            }

            var configurer: (LabelView, Model) -> Void {
                { view, model in
                    view.label.text = model.text
                    view.label.font = UIFont.systemFont(ofSize: model.fontSize)
                }
            }

            let label = UILabel()

            override init(frame: CGRect) {
                super.init(frame: frame)
                addSubview(label)
            }

            required init?(coder: NSCoder) {
                fatalError("init(coder:) has not been implemented")
            }
        }

        // Given
        let view = LabelView()
        let model = LabelView.Model(text: "Swift", fontSize: 20)

        // When
        view.ss.configure(model)

        // Then
        XCTAssertEqual(view.label.text, "Swift")
        XCTAssertEqual(view.label.font.pointSize, 20)
    }

    // MARK: - Thread Safety

    func test_configure_from_multiple_threads() {
        // Given
        let view = TestConfigurableUIView()
        let expectation = XCTestExpectation(description: "Concurrent configurations")

        // When
        let group = DispatchGroup()
        let queue = DispatchQueue.global(qos: .userInitiated)

        for i in 0..<50 {
            group.enter()
            queue.async {
                let model = TestConfigurableUIView.Model(
                    text: "Thread\(i)",
                    value: i
                )

                Task { @MainActor in
                    view.ss.configure(model)
                    group.leave()
                }
            }
        }

        group.notify(queue: .main) {
            // All configurations completed
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 5.0)

        // Then
        XCTAssertEqual(view.configureCallCount, 50)
    }

    // MARK: - Complex Model Types

    func test_configure_with_struct_model() {
        struct ComplexModel {
            let id: UUID
            let title: String
            let items: [String]
            let metadata: [String: Any]
        }

        class ComplexView: UIView, Configurable {
            var lastModel: ComplexModel?

            var configurer: (ComplexView, ComplexModel) -> Void {
                { view, model in
                    view.lastModel = model
                }
            }
        }

        // Given
        let view = ComplexView()
        let model = ComplexModel(
            id: UUID(),
            title: "Hip Hop",
            items: ["Show", "Me", "The", "Money"],
            metadata: ["key": "value"]
        )

        // When
        view.ss.configure(model)

        // Then
        XCTAssertEqual(view.lastModel?.id, model.id)
        XCTAssertEqual(view.lastModel?.title, model.title)
        XCTAssertEqual(view.lastModel?.items, model.items)
    }

    func test_configure_with_class_model() {
        class ReferenceModel {
            let value: String
            var counter: Int = 0

            init(value: String) {
                self.value = value
            }
        }

        class ReferenceView: UIView, Configurable {
            var lastModel: ReferenceModel?

            var configurer: (ReferenceView, ReferenceModel) -> Void {
                { view, model in
                    model.counter += 1
                    view.lastModel = model
                }
            }
        }

        // Given
        let view = ReferenceView()
        let model = ReferenceModel(value: "Test")

        // When
        view.ss.configure(model)

        // Then
        XCTAssertEqual(model.counter, 1)
        XCTAssertTrue(view.lastModel === model)
    }

    // MARK: - Empty/Default Configurations

    func test_configure_with_empty_model() {
        struct EmptyModel {}

        class EmptyConfigView: UIView, Configurable {
            var configureCount = 0

            var configurer: (EmptyConfigView, EmptyModel) -> Void {
                { view, _ in
                    view.configureCount += 1
                }
            }
        }

        // Given
        let view = EmptyConfigView()
        let model = EmptyModel()

        // When
        view.ss.configure(model)

        // Then
        XCTAssertEqual(view.configureCount, 1)
    }

    // MARK: - Error Scenarios

    func test_configure_does_not_crash_on_invalid_state() {
        class FragileView: UIView, Configurable {
            var isValid = true
            var lastValue: String?

            var configurer: (FragileView, String) -> Void {
                { view, model in
                    guard view.isValid else { return }
                    view.lastValue = model
                }
            }
        }

        // Given
        let view = FragileView()
        view.isValid = false

        // When
        XCTAssertNoThrow(
            view.ss.configure("Test")
        )

        // Then
        XCTAssertNil(view.lastValue)
    }

    // MARK: - MainActor + Actor Crossing

    func test_main_actor_label_configuration() {
        class MyLabel: UILabel, Configurable {
            struct ViewModel { let text: String }

            var configurer: (MyLabel, ViewModel) -> Void {
                { label, model in
                    label.text = model.text
                }
            }
        }

        // Given
        let view = MyLabel()
        let model = MyLabel.ViewModel(text: "Hello, Actor!")

        // When
        view.ss.configure(model)

        // Then
        XCTAssertEqual(view.text, "Hello, Actor!")
    }

    func test_main_actor_with_async_worker() async throws {
        class MyLabel: UILabel, Configurable {
            struct ViewModel { let text: String }

            var configurer: (MyLabel, ViewModel) -> Void {
                { label, model in
                    label.text = model.text
                }
            }
        }

        @MainActor
        final class MyUIComponent {
            private let view: MyLabel

            init(view: MyLabel) {
                self.view = view
            }

            func configure(with model: MyLabel.ViewModel) {
                view.ss.configure(model)
            }

            var currentText: String? {
                view.text
            }
        }

        actor BackgroundWorker {
            func load() async throws -> MyLabel.ViewModel {
                try await Task.sleep(nanoseconds: 3_000_000_000)
                return .init(text: "Updated")
            }
        }

        // Given
        let view = MyLabel()
        let ui = MyUIComponent(view: view)
        let worker = BackgroundWorker()

        // When
        let model = try await worker.load()
        ui.configure(with: model)

        // Then
        let result = ui.currentText
        XCTAssertEqual(result, "Updated")
    }

    func test_configure_from_background_thread() {
        // Given
        let expectation = XCTestExpectation(description: "Configure from background")
        let view = TestConfigurableUIView()
        let model = TestConfigurableUIView.Model(text: "Background", value: 30)

        // When
        DispatchQueue.global(qos: .userInitiated).async {
            Task { @MainActor in
                view.ss.configure(model)
                XCTAssertEqual(view.lastModel?.text, "Background")
                expectation.fulfill()
            }
        }

        // Then
        wait(for: [expectation], timeout: 2.0)
    }

    func test_data_crossing_actor_boundaries() async {
        actor DataStore {
            var items: [TestConfigurableUIView.Model] = []

            func add(_ item: TestConfigurableUIView.Model) {
                items.append(item)
            }

            func getAll() -> [TestConfigurableUIView.Model] {
                items
            }
        }

        // Given
        let store = DataStore()
        let view = TestConfigurableUIView()

        // When
        await store.add(TestConfigurableUIView.Model(text: "A", value: 1))
        await store.add(TestConfigurableUIView.Model(text: "B", value: 2))

        let items = await store.getAll()
        for item in items {
            view.ss.configure(item)
        }

        // Then
        XCTAssertEqual(view.configureCallCount, 2)
        XCTAssertEqual(view.lastModel?.text, "B")
    }

    func test_concurrent_configuration_updates() {
        // Given
        let view = TestConfigurableUIView()
        let expectation = XCTestExpectation(description: "Concurrent updates")

        let group = DispatchGroup()
        let queue = DispatchQueue.global(qos: .userInitiated)

        // When
        for i in 0..<100 {
            group.enter()
            queue.async {
                let model = TestConfigurableUIView.Model(text: "Config\(i)", value: i)
                Task { @MainActor in
                    view.ss.configure(model)
                    group.leave()
                }
            }
        }

        // Then
        group.notify(queue: .main) {
            XCTAssertEqual(view.configureCallCount, 100, "All configurations have been applied")
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 5.0)
    }
}
#endif
