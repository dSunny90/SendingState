//
//  Boundable.swift
//  SendingState
//
//  Created by SunSoo Jeon on 01.02.2021.
//

/// Describes how a data model is bound to a configurable UI component.
///
/// Maps a data model (`DataType`) to a UI component (`Binder`) that renders it.
/// `Binder` must conform to `Configurable`.
public protocol Boundable {
    /// The type of data to bind to the UI component.
    associatedtype DataType
    /// The UI type that renders the data.
    associatedtype Binder: Configurable where Binder.Input == DataType

    /// The actual data to render.
    var contentData: DataType? { get set }
    /// The view type used to render the data.
    var binderType: Binder.Type { get }

    /// Optional identifier to distinguish between boundables
    var identifier: String? { get }
}

public extension Boundable {
    var identifier: String? { nil }

    func bound(to binder: Binder) {
        guard let input = contentData else { return }
        binder.configurer(binder, input)
    }

    /// Erases the concrete type for flexible API use.
    ///
    /// Keeps binding behavior while hiding the type.
    /// - Returns: A type-erased wrapper.
    func eraseToAnyBoundable() -> AnyBoundable { AnyBoundable(self) }
}
