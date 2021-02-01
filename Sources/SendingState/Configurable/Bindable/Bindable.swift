//
//  Bindable.swift
//  SendingState
//
//  Created by SunSoo Jeon on 01.02.2021.
//

/// Describes how a data model is bound to a configurable UI component.
///
/// Maps a data model (`DataType`) to a UI component (`Binder`) that renders it.
/// `Binder` must conform to `Configurable`.
public protocol Bindable {
    /// The type of data to bind to the UI component.
    associatedtype DataType
    /// The UI type that renders the data.
    associatedtype Binder: Configurable where Binder.Input == DataType

    /// The actual data to render.
    var contentData: DataType? { get set }
    /// The view type used to render the data.
    var binderType: Binder.Type { get }

    /// Optional identifier to distinguish between bindables
    var identifier: String? { get }
}

public extension Bindable {
    var identifier: String? { nil }

    func bind(to binder: Binder) {
        guard let input = contentData else { return }
        binder.configurer(binder, input)
    }
}
