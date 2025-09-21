//
//  Boundable.swift
//  SendingState
//
//  Created by SunSoo Jeon on 01.02.2021.
//

/// Describes how a data model is bound to a configurable UI component.
///
/// Maps a data model (`DataType`) to a UI component (`Binder`) that renders it.
/// `Binder` must conform to ``Configurable``, which is `@MainActor`-isolated.
public protocol Boundable: Sendable {
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
    var identifier: String? { nil }

    /// Applies `contentData` to the binder using its `configurer`.
    /// Must be called on the main actor because `Configurable` is
    /// `@MainActor`-isolated.
    ///
    /// - Parameter binder: The component to configure.
    @MainActor
    func apply(to binder: Binder) {
        guard let input = contentData else { return }
        binder.configurer(binder, input)
    }

    /// Erases the concrete type for flexible APIs.
    ///
    /// Preserves binding behavior while hiding the concrete type.
    /// - Returns: A type-erased wrapper.
    func eraseToAnyBoundable() -> AnyBoundable { AnyBoundable(self) }
}
