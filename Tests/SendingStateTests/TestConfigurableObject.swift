//
//  TestConfigurableObject.swift
//  SendingState
//
//  Created by SunSoo Jeon on 23.06.2023.
//

import Foundation
@testable import SendingState

@MainActor
final class TestConfigurableObject: Configurable {
    var inputValue: String?

    var configurer: (TestConfigurableObject, String) -> Void = { obj, input in
        obj.inputValue = input
    }

    init() {}
}
