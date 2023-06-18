//
//  BoundableTests.swift
//  SendingState
//
//  Created by SunSoo Jeon on 01.02.2021.
//

import XCTest
@testable import SendingState

final class TestObject: Configurable {
    var inputValue: String?
    var configurer: (TestObject, String) -> Void = { obj, input in
        obj.inputValue = input
    }
}

struct TestModel: Boundable {
    typealias DataType = String
    typealias Binder = TestObject

    var contentData: String?
    var binderType: TestObject.Type { TestObject.self }
}

final class BoundableTests: XCTestCase {
    func testBoundableConfiguresBinderCorrectly() {
        let model = TestModel(contentData: "Hello")
        let obj = TestObject()

        model.bound(to: obj)

        XCTAssertEqual(obj.inputValue, "Hello")
    }

    func testAnyBoundableConfiguresBinderCorrectly() {
        let model = TestModel(contentData: "Hello")
        let erased = AnyBoundable(model)
        let obj = TestObject()

        erased.bound(to: obj)

        XCTAssertEqual(obj.inputValue, "Hello")
    }

    func testAnyBoundableDoesNotCrashOnInvalidBinder() {
        let model = TestModel(contentData: "Hello")
        let erased = AnyBoundable(model)

        // Pass unrelated type as binder – should be no crash or side effect
        class Dummy {}

        let dummy = Dummy()
        XCTAssertNoThrow(erased.bound(to: dummy))
    }

    func testBoundableThreadSafetyUnderLoad() {
        let model = TestModel(contentData: "ThreadSafe")
        let erased = AnyBoundable(model)
        let expectation = XCTestExpectation(description: "Thread safety check")

        let obj = TestObject()
        let queue = DispatchQueue.global(qos: .userInitiated)

        let group = DispatchGroup()
        for _ in 0..<1000 {
            group.enter()
            queue.async {
                erased.bound(to: obj)
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
