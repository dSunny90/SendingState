//
//  AnyBindable.swift
//  SendingState
//
//  Created by SunSoo Jeon on 20.02.2021.
//

import Foundation

/// A fully type-erased `Bindable` instance.
///
/// Enables storage of heterogeneous `Bindable` types in collections.
public struct AnyBindable: Hashable {
    /// The underlying content data, type-erased as `Any`.
    public var contentData: Any? { _contentData() }

    /// The expected binder type to which configuration should be applied.
    public var binderType: Any.Type { _binderType }

    /// An optional identifier used to distinguish this bindable instance.
    public var identifier: String? { _identifier() }

    internal let uuid: UUID = UUID()

    private let _contentData: () -> Any?
    private let _binderType: Any.Type

    private let _bindingBlock: (Any) -> Void
    private let _sizeBlock: ((CGSize) -> CGSize)?

    private let _identifier: () -> String?

    /// Creates a type-erased bindable from a concrete `Bindable`.
    ///
    /// - Parameter bindable: The concrete `Bindable` to wrap.
    public init<T: Bindable>(_ bindable: T) {
        _contentData = { bindable.contentData }
        _binderType = T.Binder.self
        _bindingBlock = { anyBinder in
            guard let concreteBinder = anyBinder as? T.Binder,
                  let input = bindable.contentData
            else { return }
            concreteBinder.configurer(concreteBinder, input)
        }
        _sizeBlock = { size in
            guard let input = bindable.contentData else { return .zero }
            return T.Binder.size(with: input, constrainedTo: size) ?? .zero
        }
        _identifier = { bindable.identifier }
    }

    /// Applies the configuration to the given binder instance.
    ///
    /// - Parameter binder: An instance that should match `binderType`.
    public func bind(to binder: Any) {
        _bindingBlock(binder)
    }

    public func size(constrainedTo size: CGSize) -> CGSize {
        return _sizeBlock?(size) ?? .zero
    }

    // MARK: - Hashable
    public func hash(into hasher: inout Hasher) {
        hasher.combine(uuid)
    }

    public static func == (lhs: AnyBindable, rhs: AnyBindable) -> Bool {
        return lhs.uuid == rhs.uuid
    }
}
