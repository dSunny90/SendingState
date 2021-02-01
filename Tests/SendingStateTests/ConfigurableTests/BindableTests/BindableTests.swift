//
//  BindableTests.swift
//  SendingState
//
//  Created by SunSoo Jeon on 01.02.2021.
//

import XCTest
@testable import SendingState

final class BindableTests: XCTestCase {
    func testBindableConfiguresBinderCorrectly() {
        let model = TestModel(contentData: "Hello")
        let obj = TestObject()

        model.apply(to: obj)

        XCTAssertEqual(obj.inputValue, "Hello")
    }
}

extension BindableTests {
    final class TestObject: Configurable {
        var inputValue: String?
        var configurer: (TestObject, String) -> Void = { obj, input in
            obj.inputValue = input
        }
    }

    struct TestModel: Bindable {
        typealias DataType = String
        typealias Binder = TestObject

        var contentData: String?
        var binderType: TestObject.Type { TestObject.self }
    }
}
