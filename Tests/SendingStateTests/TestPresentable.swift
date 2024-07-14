//
//  TestPresentable.swift
//  SendingState
//
//  Created by SunSoo Jeon on 02.11.2022.
//

@testable import SendingState

struct TestPresentable: Presentable {
    typealias State = Int

    final class Binder: Configurable {
        typealias Input = Int
        var lastConfigured: Int?

        var configurer: (TestPresentable.Binder, Int) -> Void {
            { binder, model in
                binder.lastConfigured = model
            }
        }
    }

    var state: Int
    var binderType: Binder.Type { Binder.self }

    init(state: Int = 0) {
        self.state = state
    }

    @MainActor
    func apply(to binder: Binder) {
        SendingState(binder).configure(state)
    }
}
