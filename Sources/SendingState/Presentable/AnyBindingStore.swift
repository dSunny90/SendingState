//
//  AnyBindingStore.swift
//  SendingState
//
//  Created by SunSoo Jeon on 06.01.2021.
//

import Foundation

/// A type-erased wrapper around `BindingStore`.
///
/// `AnyBindingStore` makes it possible to store heterogeneous
/// `BindingStore<State, Binder>` instances in a single collection
/// while still exposing a unified interface for configuration,
/// state updates, size calculation, and state observation.
///
/// This wrapper strongly retains the underlying `BindingStore`.
open class AnyBindingStore {
    /// An optional identifier forwarded from the underlying store.
    public let identifier: String?

    /// The current type-erased state held by the underlying store.
    public var state: Any {
        get {
            _getStateBlock()
        }
        set {
            _setStateBlock(newValue)
        }
    }

    /// The current type-erased binder type associated with this store.
    public let binderType: Any.Type

    private let _getStateBlock: () -> Any
    private let _setStateBlock: (Any) -> Void
    private let _applyBlock: @MainActor (Any) -> Void
    private let _observeBlock: (@escaping (Any) -> Void) -> StateObservationToken
    private let _sizeBlock: (CGSize?) -> CGSize?
    private let _decodeStateBlock: (Data, JSONDecoder) throws -> Any

    /// Creates a type-erased wrapper from a concrete `BindingStore`.
    ///
    /// - Parameter store: The concrete store to erase.
    public init<State, Binder>(_ store: BindingStore<State, Binder>) {
        identifier = store.identifier
        binderType = Binder.self

        _getStateBlock = { store.state }
        _setStateBlock = { newState in
            guard let newState = newState as? State else {
                assertionFailure(
                    "⚠️ [SendingState] AnyBindingStore.state received an incompatible state type. " +
                    "Expected \(State.self), got \(type(of: newState))."
                )
                return
            }

            store.state = newState
        }

        _applyBlock = { binder in
            guard let concreteBinder = binder as? Binder else {
                assertionFailure(
                    "⚠️ [SendingState] AnyBindingStore.apply(to:) received an incompatible binder type. " +
                    "Expected \(Binder.self), got \(type(of: binder))."
                )
                return
            }

            store.apply(to: concreteBinder)
        }

        _observeBlock = { observer in
            store.observe { value in
                observer(value)
            }
        }

        _sizeBlock = { size in
            return Binder.size(with: store.state, constrainedTo: size)
        }

        _decodeStateBlock = _AnyBindingStoreDecoderFactory<State>.stateBlock()
    }

    /// Applies the underlying store state to the given binder.
    ///
    /// If the given binder does not match the underlying binder type,
    /// this method becomes a no-op in release builds and triggers an
    /// assertion in debug builds.
    ///
    /// - Parameter binder: A binder expected to match the wrapped
    ///                     store's binder type.
    @MainActor
    public func apply(to binder: Any) {
        _applyBlock(binder)
    }

    /// Registers an observer for state changes from the underlying store.
    ///
    /// The observer receives the current state immediately upon registration.
    ///
    /// - Parameter observer: A closure invoked with type-erased state updates.
    /// - Returns: A token that controls the lifetime of the observation.
    @discardableResult
    public func observe(
        _ observer: @escaping (Any) -> Void
    ) -> StateObservationToken {
        _observeBlock(observer)
    }

    /// Calculates the size needed to display the current state.
    ///
    /// - Parameter size: An optional size constraint from the parent container.
    /// - Returns: The estimated size required to display the input,
    ///            or `nil` if no size calculation is needed.
    public func size(constrainedTo size: CGSize?) -> CGSize? {
        return _sizeBlock(size)
    }
}

private struct _AnyEncodable: Encodable {
    private let _encode: (Encoder) throws -> Void
    init<T: Encodable>(_ value: T) {
        _encode = { encoder in
            try value.encode(to: encoder)
        }
    }
    func encode(to encoder: Encoder) throws { try _encode(encoder) }
}

private struct _AnyBindingStorePayload: Encodable {
    let state: _AnyEncodable
    let binderType: String
}

private struct _AnyBindingStoreDecodablePayload<State: Decodable>: Decodable {
    let state: State
    let binderType: String
}

private enum _AnyBindingStoreDecoderFactory<T> {
    static func stateBlock() -> (Data, JSONDecoder) throws -> Any {
        return { _, _ in
            throw DecodingError.typeMismatch(T.self, .init(codingPath: [], debugDescription: "State does not conform to Decodable."))
        }
    }
}

private extension _AnyBindingStoreDecoderFactory where T: Decodable {
    static func stateBlock() -> (Data, JSONDecoder) throws -> Any {
        return { data, decoder in
            try decoder.decode(T.self, from: data)
        }
    }
}

extension AnyBindingStore: Hashable {
    public static func == (lhs: AnyBindingStore, rhs: AnyBindingStore) -> Bool {
        lhs === rhs
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
}

public extension AnyBindingStore {
    /// Encodes the underlying store's current state as a JSON payload.
    ///
    /// The resulting object contains two fields:
    /// - `state`: the encoded state value
    /// - `binderType`: the type name of the associated binder
    ///
    /// - Parameter prettyPrinted: Pass `true` to format the output
    ///                            for readability. Defaults to `false`.
    /// - Returns: UTF-8 encoded JSON data.
    /// - Throws: `EncodingError.invalidValue` if the underlying state
    ///           does not conform to `Encodable`.
    func toJSONData(prettyPrinted: Bool = false) throws -> Data {
        // Attempt to wrap the underlying state as Encodable
        guard let encodableState = state as? Encodable else {
            throw EncodingError.invalidValue(state, .init(codingPath: [], debugDescription: "Underlying state does not conform to Encodable."))
        }

        let payload = _AnyBindingStorePayload(
            state: _AnyEncodable(encodableState),
            binderType: String(describing: binderType)
        )
        let encoder = JSONEncoder()
        if prettyPrinted { encoder.outputFormatting.insert(.prettyPrinted) }
        return try encoder.encode(payload)
    }

    /// Returns the underlying store's current state as a JSON string.
    ///
    /// See ``toJSONData(prettyPrinted:)`` for the payload structure
    /// and error behavior.
    ///
    /// - Parameter prettyPrinted: Pass `true` to format the output
    ///                            for readability. Defaults to `false`.
    /// - Returns: A UTF-8 JSON string.
    /// - Throws: `EncodingError.invalidValue` if the underlying state
    ///           does not conform to `Encodable`.
    func toJSONString(prettyPrinted: Bool = false) throws -> String {
        let data = try toJSONData(prettyPrinted: prettyPrinted)
        return String(decoding: data, as: UTF8.self)
    }
}

public extension AnyBindingStore {
    /// Decodes a state value from JSON data and updates the underlying store.
    ///
    /// - Parameters:
    ///   - data: UTF-8 encoded JSON representing the underlying state type.
    ///   - decoder: The decoder to use. Defaults to a new `JSONDecoder`.
    /// - Throws: A decoding error if `data` cannot be decoded as the
    ///           underlying state type.
    func updateState(fromJSONData data: Data,
                     using decoder: JSONDecoder = JSONDecoder()) throws {
        let decoded = try _decodeStateBlock(data, decoder)
        self.state = decoded
    }

    /// Decodes a state value from a JSON string and updates the underlying store.
    ///
    /// See ``updateState(fromJSONData:using:)`` for error behavior.
    ///
    /// - Parameters:
    ///   - jsonString: A UTF-8 JSON string representing the underlying
    ///                 state type.
    ///   - decoder: The decoder to use. Defaults to a new `JSONDecoder`.
    /// - Throws: A decoding error if `jsonString` cannot be decoded as
    ///           the underlying state type.
    func updateState(fromJSONString jsonString: String,
                     using decoder: JSONDecoder = JSONDecoder()) throws {
        let data = Data(jsonString.utf8)
        try updateState(fromJSONData: data, using: decoder)
    }
}
