//
//  TestTypedBoundableObject.swift
//  SendingState
//
//  Created by SunSoo Jeon on 23.06.2023.
//

@testable import SendingState

#if os(iOS) || targetEnvironment(macCatalyst)

/// A subclass of `AnyBoundableObject` that constrains `T.Binder`
/// to `TestConfigurableProtocol`, verifying that subclassing with
/// additional generic constraints works correctly.
final class TestTypedBoundableObject: AnyBoundableObject, @unchecked Sendable {
    private let _testMethodBlock: @MainActor (Any) -> Void

    init<T: Boundable>(_ boundable: T)
        where T.Binder: TestConfigurableProtocol, T.Binder.Input == T.DataType
    {
        _testMethodBlock = { anyBinder in
            guard let binder = anyBinder as? T.Binder,
                  let input = boundable.contentData else { return }
            binder.testMethod(with: input)
        }
        super.init(boundable)
    }

    @MainActor
    func testMethod(to binder: Any) {
        _testMethodBlock(binder)
    }

}
#endif
