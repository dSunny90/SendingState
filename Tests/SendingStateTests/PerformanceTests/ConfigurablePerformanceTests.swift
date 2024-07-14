//
//  ConfigurablePerformanceTests.swift
//  SendingState
//
//  Created by SunSoo Jeon on 04.12.2022.
//

import XCTest
@testable import SendingState

#if os(iOS) || targetEnvironment(macCatalyst)
import UIKit

@MainActor
final class ConfigurablePerformanceTests: XCTestCase {
    // MARK: - Configuration Performance

    /// Measure single configuration performance
    func test_single_configure_performance() {
        let view = TestConfigurableUIView()
        let model = TestConfigurableUIView.Model(text: "Performance Test", value: 11)

        measure {
            for _ in 0..<10000 {
                view.ss.configure(model)
            }
        }
    }

    /// Measure configuration with varying model complexity
    func test_configure_with_complex_model_performance() {
        class ComplexView: UIView, Configurable {
            struct Model {
                let id: UUID
                let title: String
                let subtitle: String
                let items: [String]
                let metadata: [String: String]
            }

            var configurer: (ComplexView, Model) -> Void {
                { _, _ in }
            }
        }

        let view = ComplexView()
        let model = ComplexView.Model(
            id: UUID(),
            title: "Hello, SendingState World!",
            subtitle: "Hi, Bonjour, Guten Tag, Ciao, Hola, 안녕!",
            items: Array(repeating: "Item", count: 100),
            metadata: Dictionary(uniqueKeysWithValues: (0..<50).map { ("key\($0)", "value\($0)") })
        )

        measure {
            for _ in 0..<10000 {
                view.ss.configure(model)
            }
        }
    }

    // MARK: - BindingStore Performance

    /// Measure store creation and binding
    func test_bindingStore_performance() {
        let view = TestConfigurableUIView()

        measure {
            for i in 0..<10000 {
                let viewModel = BindingStore<TestConfigurableUIView.Model, TestConfigurableUIView>(
                    state: TestConfigurableUIView.Model(text: "Item\(i)", value: i)
                )
                viewModel.apply(to: view)
            }
        }
    }

    /// Measure AnyBindingStore type erasure overhead
    func test_anyBindingStore_type_erasure_performance() {
        let view = TestConfigurableUIView()

        measure {
            for i in 0..<10000 {
                let viewModel = BindingStore<TestConfigurableUIView.Model, TestConfigurableUIView>(
                    state: TestConfigurableUIView.Model(text: "Item\(i)", value: i)
                )
                let erased = viewModel.eraseToAnyBindingStore()
                erased.apply(to: view)
            }
        }
    }

    // MARK: - Collection Operations

    /// Measure binding array of stores
    func test_array_binding_performance() {
        let views = (0..<1000).map { _ in TestConfigurableUIView() }
        let stores = (0..<1000).map { i in
            BindingStore<TestConfigurableUIView.Model, TestConfigurableUIView>(
                state: TestConfigurableUIView.Model(text: "Item\(i)", value: i)
            ).eraseToAnyBindingStore()
        }

        measure {
            for (store, view) in zip(stores, views) {
                store.apply(to: view)
            }
        }
    }

    /// Measure size calculation performance
    func test_size_calculation_performance() {
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
                let height = CGFloat(input.lines * 30)
                return CGSize(width: parentSize?.width ?? 320, height: height)
            }
        }

        let stores = (0..<100).map { i in
            BindingStore<SizableView.Model, SizableView>(state: SizableView.Model(lines: i + 1)).eraseToAnyBindingStore()
        }

        let constraint = CGSize(width: 375, height: 812)

        measure {
            for _ in 0..<1000 {
                for store in stores {
                    _ = store.size(constrainedTo: constraint)
                }
            }
        }
    }

    // MARK: - Reconfiguration Performance

    /// Measure repeated reconfiguration of same view
    func test_reconfiguration_performance() {
        let view = TestConfigurableUIView()
        let models = (0..<1000).map { i in
            TestConfigurableUIView.Model(text: "Model\(i)", value: i)
        }

        measure {
            for _ in 0..<100 {
                for model in models {
                    view.ss.configure(model)
                }
            }
        }
    }

    // MARK: - Memory Allocation

    /// Measure memory allocation during configuration
    func test_configuration_memory_allocation() {
        var views: [TestConfigurableUIView] = []

        measure(metrics: [XCTMemoryMetric()]) {
            views.removeAll()
            for i in 0..<1000 {
                let view = TestConfigurableUIView()
                let model = TestConfigurableUIView.Model(text: "Item\(i)", value: i)
                view.ss.configure(model)
                views.append(view)
            }
        }
    }
}
#endif
