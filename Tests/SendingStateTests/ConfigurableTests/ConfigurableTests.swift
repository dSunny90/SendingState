//
//  ConfigurableTests.swift
//  SendingState
//
//  Created by SunSoo Jeon on 23.11.2020.
//

import XCTest
@testable import SendingState

final class ConfigurableTests: XCTestCase {
    struct Model { let value: String }

    final class Controller: Configurable {
        var value: String = ""

        var configurer: (Controller, Model) -> Void {
            { controller, model in
                controller.value = model.value
            }
        }
    }

    func testConfigureAppliesModelValue() {
        let controller = Controller()
        let model = Model(value: "Hello, World!")

        controller.configurer(controller, model)

        XCTAssertEqual(controller.value, "Hello, World!")
    }
}

#if os(iOS) || targetEnvironment(macCatalyst)
import UIKit

extension ConfigurableTests {
    final class LabelView: UIView, Configurable {
        struct Model {
            let text: String
            let fontSize: CGFloat
        }

        var configurer: (LabelView, Model) -> Void {
            { view, model in
                DispatchQueue.main.async {
                    view.label.text = model.text
                    view.label.font = UIFont.systemFont(ofSize: model.fontSize)
                }
            }
        }

        private let label = UILabel()

        override init(frame: CGRect) {
            super.init(frame: frame)
            addSubview(label)
            label.frame = bounds
            label.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        static func size(with input: Model?,
                         constrainedTo parentSize: CGSize?) -> CGSize? {
            guard let input = input else { return nil }
            let width = parentSize?.width ?? 100
            let height = input.text.count > 10 ? 60 : 40
            return CGSize(width: width, height: CGFloat(height))
        }
    }

    func testConfigureUpdatesLabelMainThread() {
        DispatchQueue.main.async {
            let view = LabelView()
            let model = LabelView.Model(text: "Hello", fontSize: 20)

            view.ss.configure(model)

            let label = view.subviews.compactMap { $0 as? UILabel }.first
            XCTAssertEqual(label?.text, "Hello")
            XCTAssertEqual(label?.font.pointSize, 20)
        }
    }

    func testConfigureUpdatesLabelThread() {
        let view = LabelView()
        let model = LabelView.Model(text: "Hello", fontSize: 20)

        view.ss.configure(model)

        let label = view.subviews.compactMap { $0 as? UILabel }.first
        XCTAssertEqual(label?.text, nil)
    }

    func testSizeWithModel() {
        let model = LabelView.Model(text: "Short", fontSize: 14)
        let parentSize = CGSize(width: 200, height: 100)

        let size = LabelView.size(with: model, constrainedTo: parentSize)

        XCTAssertEqual(size?.width, 200)
        XCTAssertEqual(size?.height, 40)
    }

    func testSizeWithLongText() {
        let model = LabelView.Model(text: "This is a very long string",
                                    fontSize: 14)
        let size = LabelView.size(with: model,
                                  constrainedTo: .init(width: 150, height: 200))

        XCTAssertEqual(size?.height, 60)
    }

    func testSizeNilModel() {
        let size = LabelView.size(with: nil, constrainedTo: nil)
        XCTAssertNil(size)
    }
}

#endif
