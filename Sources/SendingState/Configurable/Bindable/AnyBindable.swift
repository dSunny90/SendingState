//
//  AnyBindable.swift
//  SendingState
//
//  Created by SunSoo Jeon on 20.02.2021.
//

import Foundation

/// A type-erased `Bindable` wrapper.
///
/// Enables storage of heterogeneous `Bindable` types in collections.
public struct AnyBindable: Hashable {
    /// The underlying content data, type-erased to `Any`.
    public var contentData: Any? { _contentData() }

    /// The binder type that can receive this configuration.
    public var binderType: Any.Type { _binderType }

    /// An optional identifier for distinguishing this instance.
    public var identifier: String? { _identifier() }

    @usableFromInline
    internal let uuid: UUID = UUID()

    private let _contentData: () -> Any?
    private let _binderType: Any.Type

    private let _bindingBlock: (Any) -> Void
    private let _sizeBlock: ((CGSize?) -> CGSize?)?

    private let _identifier: () -> String?

    /// Creates a type-erased wrapper from a concrete `Bindable`.
    ///
    /// - Parameter bindable: The concrete `Bindable` to wrap.
    public init<T: Bindable>(_ bindable: T) {
        _contentData = { bindable.contentData }
        _binderType = T.Binder.self
        _bindingBlock = { anyBinder in
            guard let concreteBinder = anyBinder as? T.Binder,
                  let input = bindable.contentData else { return }
            SendingState<T.Binder>(concreteBinder).configure(input)
        }
        _sizeBlock = { size in
            guard let input = bindable.contentData else { return nil }
            return T.Binder.size(with: input, constrainedTo: size)
        }
        _identifier = { bindable.identifier }
    }

    /// Applies the configuration to the given binder.
    ///
    /// - Parameter binder: A binder instance matching `binderType`.
    public func apply(to binder: Any) {
        _bindingBlock(binder)
    }

    /// Calculates the size needed to display the content.
    ///
    /// - Parameter size: An optional size constraint from the parent container.
    /// - Returns: The estimated size required to display the input,
    ///            or `nil` if no size calculation is needed.
    public func size(constrainedTo size: CGSize?) -> CGSize? {
        return _sizeBlock?(size)
    }

    // MARK: - Hashable
    @inlinable
    public func hash(into hasher: inout Hasher) {
        hasher.combine(uuid)
    }

    @inlinable
    public static func == (lhs: AnyBindable, rhs: AnyBindable) -> Bool {
        return lhs.uuid == rhs.uuid
    }
}
