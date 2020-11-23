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
