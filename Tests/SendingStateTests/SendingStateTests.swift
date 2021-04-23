//
//  SendingStateTests.swift
//  SendingState
//
//  Created by SunSoo Jeon on 20.11.2020.
//

import XCTest
@testable import SendingState

final class SendingStateTests: XCTestCase {}

#if os(iOS) || targetEnvironment(macCatalyst)
import UIKit

extension SendingStateTests {
    func test_state() {
        let view = SendingStateTestView()
        let model = SendingStateTestView.Model(text: "Hello, World!", value: 1)

        view.ss.configure(model)

        let result = view.ss.state()
        XCTAssertEqual(result, model)
    }

    final class SendingStateTestView: UIView, Configurable {
        struct Model: Equatable {
            let text: String
            let value: Int

            init(text: String, value: Int = 0) {
                self.text = text
                self.value = value
            }
        }

        var configurer: (SendingStateTestView, Model) -> Void {
            { view, model in
                // no-op
            }
        }
    }
}

#endif
