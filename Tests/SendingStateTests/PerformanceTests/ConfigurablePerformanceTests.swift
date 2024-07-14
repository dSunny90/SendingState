//
//  ConfigurablePerformanceTests.swift
//  SendingState
//
//  Created by SunSoo Jeon on 26.06.2023.
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

    // MARK: - Boundable Performance

    /// Measure boundable creation and binding
    func test_boundable_binding_performance() {
        let view = TestConfigurableUIView()

        measure {
            for i in 0..<10000 {
                let boundable = TestBoundableViewModel(
                    contentData: TestConfigurableUIView.Model(text: "Item\(i)", value: i)
                )
                boundable.apply(to: view)
            }
        }
    }

    /// Measure AnyBoundable type erasure overhead
    func test_any_boundable_type_erasure_performance() {
        let view = TestConfigurableUIView()

        measure {
            for i in 0..<10000 {
                let boundable = TestBoundableViewModel(
                    contentData: TestConfigurableUIView.Model(text: "Item\(i)", value: i)
                )
                let anyBoundable = boundable.eraseToAnyBoundable()
                anyBoundable.apply(to: view)
            }
        }
    }

    // MARK: - Collection Operations

    /// Measure binding array of boundables
    func test_array_binding_performance() {
        let views = (0..<1000).map { _ in TestConfigurableUIView() }
        let boundables = (0..<1000).map { i in
            TestBoundableViewModel(
                contentData: TestConfigurableUIView.Model(text: "Item\(i)", value: i)
            ).eraseToAnyBoundable()
        }

        measure {
            for (boundable, view) in zip(boundables, views) {
                boundable.apply(to: view)
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

        struct SizableBoundable: Boundable {
            var contentData: SizableView.Model?
            var binderType: SizableView.Type { SizableView.self }
        }

        let boundables = (0..<100).map { i in
            SizableBoundable(contentData: SizableView.Model(lines: i + 1)).eraseToAnyBoundable()
        }

        let constraint = CGSize(width: 375, height: 812)

        measure {
            for _ in 0..<1000 {
                for boundable in boundables {
                    _ = boundable.size(constrainedTo: constraint)
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
