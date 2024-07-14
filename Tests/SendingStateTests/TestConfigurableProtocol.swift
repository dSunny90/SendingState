//
//  TestConfigurableProtocol.swift
//  SendingState
//
//  Created by SunSoo Jeon on 23.06.2023.
//

@testable import SendingState

@MainActor
protocol TestConfigurableProtocol: Configurable {
    func testMethod(with input: Input?)
}
