//
//  AnyBoundable.swift
//  SendingState
//
//  Created by SunSoo Jeon on 20.02.2021.
//

import Foundation

/// A fully type-erased `Boundable` instance.
///
/// Enables storage of heterogeneous `Boundable` types in collections.
public struct AnyBoundable: Hashable {
    /// The underlying content data, type-erased as `Any`.
    public var contentData: Any? { _contentData() }

    /// The expected binder type to which configuration should be applied.
    public var binderType: Any.Type { _binderType }

    /// An optional identifier used to distinguish this boundable instance.
    public var identifier: String? { _identifier() }

    internal let uuid: UUID = UUID()

    private let _contentData: () -> Any?
    private let _binderType: Any.Type

    private let _bindingBlock: (Any) -> Void
    private let _sizeBlock: ((CGSize) -> CGSize)?

    private let _identifier: () -> String?

    /// Creates a type-erased boundable from a concrete `Boundable`.
    ///
    /// - Parameter boundable: The concrete `Boundable` to wrap.
    public init<T: Boundable>(_ boundable: T) {
        _contentData = { boundable.contentData }
        _binderType = T.Binder.self
        _bindingBlock = { anyBinder in
            guard let concreteBinder = anyBinder as? T.Binder,
                  let input = boundable.contentData
            else { return }
            concreteBinder.configurer(concreteBinder, input)
        }
        _sizeBlock = { size in
            guard let input = boundable.contentData else { return .zero }
            return T.Binder.size(with: input, constrainedTo: size) ?? .zero
        }
        _identifier = { boundable.identifier }
    }

    /// Applies the configuration to the given binder instance.
    ///
    /// - Parameter binder: An instance that should match `binderType`.
    public func bound(to binder: Any) {
        _bindingBlock(binder)
    }

    public func size(constrainedTo size: CGSize) -> CGSize {
        return _sizeBlock?(size) ?? .zero
    }

    // MARK: - Hashable
    public func hash(into hasher: inout Hasher) {
        hasher.combine(uuid)
    }

    public static func == (lhs: AnyBoundable, rhs: AnyBoundable) -> Bool {
        return lhs.uuid == rhs.uuid
    }
}
