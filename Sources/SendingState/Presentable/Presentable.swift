//
//  Presentable.swift
//  SendingState
//
//  Created by SunSoo Jeon on 31.12.2020.
//

/// A type that can present its current state to a binder.
///
/// `Presentable` models a state source that knows how to apply its latest
/// state to a specific `Binder`.
///
/// Conforming types usually act as parent-owned state holders, such as
/// `BindingStore`, or other abstractions that keep a current state value
/// and render it into a `Configurable` binder when needed.
///
/// The `State` and `Binder` types are tightly coupled at the type level:
/// - `State` represents the current data to present
/// - `Binder` is the target that renders that state
public protocol Presentable {
    associatedtype State
    associatedtype Binder: Configurable where Binder.Input == State

    /// The current state held by this presentable type.
    var state: State { get set }

    /// The concrete binder type associated with this store.
    var binderType: Binder.Type { get }

    /// Applies the current state to the given binder.
    ///
    /// - Parameter binder: A binder that renders `State`.
    func apply(to binder: Binder)
}
