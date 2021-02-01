//
//  Bindable.swift
//  SendingState
//
//  Created by SunSoo Jeon on 01.02.2021.
//

/// Describes how a data model is bound to a configurable UI component.
///
/// Maps a data model (`DataType`) to a UI component (`Binder`) that renders it.
/// `Binder` must conform to ``Configurable``.
public protocol Bindable {
    /// The type of data to bind to the UI component.
    associatedtype DataType

    /// The UI type that renders the data.
    associatedtype Binder: Configurable where Binder.Input == DataType

    /// The data to be rendered.
    var contentData: DataType? { get set }

    /// The view type used to render the data.
    var binderType: Binder.Type { get }

    /// An optional identifier to distinguish between bindables.
    var identifier: String? { get }
}

public extension Bindable {
    @inlinable
    var identifier: String? { nil }

    /// Applies `contentData` to the binder using its `configurer`.
    ///
    /// - Parameter binder: The component to configure.
    func apply(to binder: Binder) {
        guard let input = contentData else { return }
        binder.configurer(binder, input)
    }
}

#if os(iOS) || targetEnvironment(macCatalyst)
import UIKit

public extension Bindable where Binder: UIView {
    func apply(to binder: Binder) {
        guard let input = contentData else { return }
        binder.ss.configure(input)
    }
}
#endif
