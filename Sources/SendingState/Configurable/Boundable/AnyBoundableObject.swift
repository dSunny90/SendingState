//
//  AnyBoundableObject.swift
//  SendingState
//
//  Created by SunSoo Jeon on 20.02.2021.
//

// MARK: - History
// - Jun 2023: Renamed `AnyBindableObject` to `AnyBoundableObject`.
//
//   This follows the `Bindable` -> `Boundable` rename to avoid confusion with
//   SwiftUI’s `@Bindable` introduced at WWDC 23. The type-erased wrapper keeps
//   the same role, but now matches the updated naming in the binding API.

import Foundation

/// A class-based, type-erased `Boundable` wrapper.
///
/// Subclass this type to build specialized wrappers while preserving
/// reference semantics.
///
/// Use this when you need to store heterogeneous `Boundable` values in
/// collections, or when identity and stable references matter
/// (e.g. diffing, caching, or shared ownership across layers).
///
/// - Note: For value semantics, use `AnyBoundable` instead.
open class AnyBoundableObject: Hashable {
    @usableFromInline
    internal let uuid: UUID = UUID()

    /// The underlying content data, type-erased to `Any`.
    public var contentData: Any? { _contentData() }

    /// The binder type that can receive this configuration.
    public var binderType: Any.Type { _binderType }

    /// An optional identifier for distinguishing this instance.
    public var identifier: String? { _identifier() }

    private let _contentData: () -> Any?
    private let _binderType: Any.Type
    private let _bindingBlock: (Any) -> Void
    private let _sizeBlock: ((CGSize?) -> CGSize?)?
    private let _identifier: () -> String?

    /// Creates a type-erased wrapper from a concrete `Boundable`.
    ///
    /// - Parameter boundable: The concrete `Boundable` to wrap.
    public init<T: Boundable>(_ boundable: T) {
        _contentData = { boundable.contentData }
        _binderType = T.Binder.self
        _bindingBlock = { anyBinder in
            guard let concreteBinder = anyBinder as? T.Binder,
                  let input = boundable.contentData else { return }
            SendingState<T.Binder>(concreteBinder).configure(input)
        }
        _sizeBlock = { size in
            guard let input = boundable.contentData else { return nil }
            return T.Binder.size(with: input, constrainedTo: size)
        }
        _identifier = { boundable.identifier }
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
    public static func == (lhs: AnyBoundableObject, rhs: AnyBoundableObject) -> Bool {
        return lhs.uuid == rhs.uuid
    }
}
