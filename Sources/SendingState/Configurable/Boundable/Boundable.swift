//
//  Boundable.swift
//  SendingState
//
//  Created by SunSoo Jeon on 01.02.2021.
//

// MARK: - History
// - Jun 2023: Renamed `Bindable` to `Boundable`.
//
//   Apple introduced SwiftUI’s `@Bindable` at WWDC 23, and the naming overlap
//   started to cause confusion. Since the view model is what gets bound to
//   the view, `Boundable` better describes the role in this library.

/// Describes how a data model is bound to a configurable UI component.
///
/// Maps a data model (`DataType`) to a UI component (`Binder`) that renders it.
/// `Binder` must conform to ``Configurable``.
public protocol Boundable {
    /// The type of data to bind to the UI component.
    associatedtype DataType

    /// The UI type that renders the data.
    associatedtype Binder: Configurable where Binder.Input == DataType

    /// The data to be rendered.
    var contentData: DataType? { get set }

    /// The view type used to render the data.
    var binderType: Binder.Type { get }

    /// An optional identifier to distinguish between boundables.
    var identifier: String? { get }
}

public extension Boundable {
    @inlinable
    var identifier: String? { nil }

    /// Applies `contentData` to the binder using its `configurer`.
    ///
    /// - Parameter binder: The component to configure.
    func apply(to binder: Binder) {
        guard let input = contentData else { return }
        binder.configurer(binder, input)
    }

    /// Erases the concrete type for flexible APIs.
    ///
    /// Preserves binding behavior while hiding the concrete type.
    /// - Returns: A type-erased wrapper.
    @inlinable
    func eraseToAnyBoundable() -> AnyBoundable { AnyBoundable(self) }
}

#if os(iOS) || targetEnvironment(macCatalyst)
import UIKit

public extension Boundable where Binder: UIView {
    /// Applies `contentData` to a `UIView` binder via the observer pathway.
    ///
    /// This overload is preferred over the base `apply(to:)` when the binder
    /// is a `UIView`. It routes through ``SendingState/configure(_:)`` which:
    /// 1. Stores the input as the binder's state
    /// 2. Calls the binder's `configurer` to update the UI
    /// 3. Propagates the state to all senders if the binder conforms to
    ///    ``EventForwardingProvider``
    func apply(to binder: Binder) {
        guard let input = contentData else { return }
        binder.ss.configure(input)
    }
}
#endif
