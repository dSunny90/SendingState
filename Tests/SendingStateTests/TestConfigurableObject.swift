//
//  TestConfigurableObject.swift
//  SendingState
//
//  Created by SunSoo Jeon on 01.02.2021.
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
