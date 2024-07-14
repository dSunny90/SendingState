//
//  TestConfigurableUIView.swift
//  SendingState
//
//  Created by SunSoo Jeon on 23.06.2023.
//

@testable import SendingState

#if os(iOS) || targetEnvironment(macCatalyst)
import UIKit

@MainActor
final class TestConfigurableUIView: UIView, Configurable {
    struct Model: Equatable, Sendable {
        let text: String
        let value: Int

        init(text: String, value: Int = 0) {
            self.text = text
            self.value = value
        }
    }

    private(set) var configureCallCount = 0
    private(set) var lastModel: Model?

    var configurer: (TestConfigurableUIView, Model) -> Void {
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
}
#endif
