//
//  TestProtocolConfigurableUIView.swift
//  SendingState
//
//  Created by SunSoo Jeon on 23.06.2023.
//

@testable import SendingState

#if os(iOS) || targetEnvironment(macCatalyst)
import UIKit

@MainActor
final class TestProtocolConfigurableUIView: UIView, TestConfigurableProtocol {
    struct Model: Equatable, Sendable {
        let title: String
        let count: Int

        init(title: String, count: Int = 0) {
            self.title = title
            self.count = count
        }
    }

    private(set) var configureCallCount = 0
    private(set) var lastModel: Model?
    private(set) var updatedCount: Int?

    var configurer: (TestProtocolConfigurableUIView, Model) -> Void {
        { view, model in
            view.configureCallCount += 1
            view.lastModel = model
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func testMethod(with input: Model?) {
        updatedCount = input?.count
    }
}
#endif
