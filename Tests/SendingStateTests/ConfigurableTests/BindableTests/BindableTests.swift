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

    func testAnyBindableConfiguresBinderCorrectly() {
        let model = TestModel(contentData: "World")
        let erased = AnyBindable(model)
        let obj = TestObject()

        erased.apply(to: obj)

        XCTAssertEqual(obj.inputValue, "World")
    }

    func testAnyBindableDoesNotCrashOnInvalidBinder() {
        let model = TestModel(contentData: "Hello, World!")
        let erased = AnyBindable(model)

        // Pass unrelated type as binder – should be no crash or side effect
        class Dummy {}

        let dummy = Dummy()
        XCTAssertNoThrow(erased.apply(to: dummy))
    }

    func testBindableThreadSafetyUnderLoad() {
        let model = TestModel(contentData: "ThreadSafe")
        let erased = AnyBindable(model)
        let expectation = XCTestExpectation(description: "Thread safety check")

        let obj = TestObject()
        let queue = DispatchQueue.global(qos: .userInitiated)

        let group = DispatchGroup()
        for _ in 0..<1000 {
            group.enter()
            queue.async {
                erased.apply(to: obj)
                group.leave()
            }
        }

        group.notify(queue: .main) {
            XCTAssertEqual(obj.inputValue, "ThreadSafe")
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 5.0)
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
