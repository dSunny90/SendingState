//
//  BindingStore.swift
//  SendingState
//
//  Created by SunSoo Jeon on 31.12.2020.
//

import Foundation

/// A reference type that owns the latest bound state for a binder.
///
/// `BindingStore` acts as the parent model for state synchronization.
/// When applied to a binder, it pushes `state` into the binder through
/// `SendingState.configure(_:)`.
///
/// If the binder supports internal state observation through `StateObserver`,
/// changes produced by `invalidateState` from the binder are written back into
/// this store automatically.
///
/// This makes `BindingStore` suitable when the UI should be able to mutate the
/// currently bound state and the parent model must stay in sync.
public final class BindingStore<State, Binder: NSObject & Configurable>
    : Presentable, @unchecked Sendable where Binder.Input == State
{
    /// A closure type used to observe store updates.
    public typealias Observer = (State) -> Void

    public var state: State {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _state
        }
        set {
            let observers: [Observer]

            lock.lock()
            _state = newValue
            observers = Array(_observers.values)
            lock.unlock()

            observers.forEach { $0(newValue) }
        }
    }

    public var binderType: Binder.Type { Binder.self }

    /// An optional identifier for distinguishing this store.
    public let identifier: String?

    private let lock = NSRecursiveLock()

    private var _state: State
    private var _observers: [UUID: Observer] = [:]
    private var _token: StateObservationToken?

    /// Creates a store with the initial state.
    ///
    /// - Parameters:
    ///   - state: The initial state to bind to the binder.
    ///   - identifier: An optional identifier for external bookkeeping.
    public init(state: State, identifier: String? = nil) {
        self._state = state
        self.identifier = identifier
    }

    /// Applies the current store state to the given binder.
    ///
    /// This method pushes `state` into the binder using
    /// `SendingState<Binder>.configure(_:)`.
    ///
    /// If the binder owns a `StateObserver`, this method also connects
    /// binder-originated state changes back into the store so that
    /// `invalidateState` updates `state` automatically.
    ///
    /// - Parameter binder: The binder to configure.
    @MainActor
    public func apply(to binder: Binder) {
        // Cancel previously attached store observation (if any) on this binder
        binder._ss_storeObservationToken?.cancel()
        binder._ss_storeObservationToken = nil

        SendingState<Binder>(binder).configure(state)

        guard let stateObserver = binder.stateObserver else { return }

        let token = stateObserver.observe { [weak self] newState in
            guard let self = self,
                  let newState = newState as? State else { return }
            self.state = newState
        }

        // Replace any previous binder-held token with the new one so that
        // the last-applied store is the only observer of this binder.
        binder._ss_storeObservationToken?.cancel()
        binder._ss_storeObservationToken = token

        lock.lock()
        _token?.cancel()
        _token = token
        lock.unlock()
    }

    /// Registers an observer that reacts to state updates.
    ///
    /// The observer immediately receives the current `_state` upon registration.
    ///
    /// - Parameter observer: A closure invoked whenever `_state` changes.
    /// - Returns: A token that controls the lifetime of the observation.
    @discardableResult
    public func observe(_ observer: @escaping Observer) -> StateObservationToken {
        let id = UUID()
        let current: State

        lock.lock()
        _observers[id] = observer
        current = _state
        lock.unlock()

        observer(current)

        return StateObservationToken { [weak self] in
            guard let self = self else { return }
            self.removeObserver(id)
        }
    }

    private func removeObserver(_ id: UUID) {
        lock.lock()
        _observers[id] = nil
        lock.unlock()
    }
}

private enum _SSBindingStoreAssociatedKeys {
    static var storeObservationToken: UInt8 = 0
}

private extension NSObject {
    var _ss_storeObservationToken: StateObservationToken? {
        get { objc_getAssociatedObject(self, &_SSBindingStoreAssociatedKeys.storeObservationToken) as? StateObservationToken }
        set { objc_setAssociatedObject(self,
                                       &_SSBindingStoreAssociatedKeys.storeObservationToken,
                                       newValue,
                                       .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
}

private struct _BindingStoreEncodablePayload<State: Encodable>: Encodable {
    let state: State
    let binderType: String
}

private struct _BindingStoreDecodablePayload<State: Decodable>: Decodable {
    let state: State
    let binderType: String
}

public extension BindingStore {
    /// Erases the concrete type for flexible APIs.
    ///
    /// Preserves binding behavior while hiding the concrete type.
    /// - Returns: A type-erased wrapper.
    @inlinable
    func eraseToAnyBindingStore() -> AnyBindingStore { AnyBindingStore(self) }
}

extension BindingStore: Hashable {
    public static func == (
        lhs: BindingStore<State, Binder>,
        rhs: BindingStore<State, Binder>
    ) -> Bool {
        lhs === rhs
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
}

public extension BindingStore where State: Encodable {
    /// Encodes the store's current state as a JSON payload.
    ///
    /// The resulting object contains two fields:
    /// - `state`: the encoded `State` value
    /// - `binderType`: the type name of the associated `Binder`
    ///
    /// - Parameter prettyPrinted: Pass `true` to format the output
    ///                            for readability. Defaults to `false`.
    /// - Returns: UTF-8 encoded JSON data.
    func toJSONData(prettyPrinted: Bool = false) throws -> Data {
        let payload = _BindingStoreEncodablePayload(
            state: state,
            binderType: String(describing: Binder.self)
        )
        let encoder = JSONEncoder()
        if prettyPrinted { encoder.outputFormatting.insert(.prettyPrinted) }
        return try encoder.encode(payload)
    }

    /// Returns the store's current state as a JSON string.
    ///
    /// See ``toJSONData(prettyPrinted:)`` for the payload structure.
    ///
    /// - Parameter prettyPrinted: Pass `true` to format the output
    ///                            for readability. Defaults to `false`.
    /// - Returns: A UTF-8 JSON string.
    func toJSONString(prettyPrinted: Bool = false) throws -> String {
        let data = try toJSONData(prettyPrinted: prettyPrinted)
        return String(decoding: data, as: UTF8.self)
    }
}

public extension BindingStore where State: Decodable {
    /// Creates a new store by decoding a `State` value from JSON data.
    ///
    /// - Parameters:
    ///   - data: UTF-8 encoded JSON representing `State`.
    ///   - decoder: The decoder to use. Defaults to a new `JSONDecoder`.
    /// - Returns: A new store whose `state` is decoded from `data`.
    /// - Throws: A decoding error if `data` cannot be decoded as `State`.
    static func decode(
        from data: Data,
        using decoder: JSONDecoder = JSONDecoder()
    ) throws -> Self {
        let state = try decoder.decode(State.self, from: data)
        return .init(state: state)
    }

    /// Creates a new store by decoding a `State` value from a JSON string.
    ///
    /// See ``decode(from:using:)-data`` for error behavior.
    ///
    /// - Parameters:
    ///   - jsonString: A UTF-8 JSON string representing `State`.
    ///   - decoder: The decoder to use. Defaults to a new `JSONDecoder`.
    /// - Returns: A new store whose `state` is decoded from `jsonString`.
    /// - Throws: `CocoaError(.fileReadInapplicableStringEncoding)` if
    ///           `jsonString` cannot be converted to UTF-8 data, or a
    ///           decoding error if the data cannot be decoded as `State`.
    static func decode(
        from jsonString: String,
        using decoder: JSONDecoder = JSONDecoder()
    ) throws -> Self {
        guard let data = jsonString.data(using: .utf8) else {
            throw CocoaError(.fileReadInapplicableStringEncoding)
        }
        return try decode(from: data, using: decoder)
    }

    /// Decodes a `State` value from JSON data and updates the store.
    ///
    /// - Parameters:
    ///   - data: UTF-8 encoded JSON representing `State`.
    ///   - decoder: The decoder to use. Defaults to a new `JSONDecoder`.
    /// - Throws: A decoding error if `data` cannot be decoded as `State`.
    func updateState(fromJSONData data: Data,
                     using decoder: JSONDecoder = JSONDecoder()) throws {
        let decoded = try decoder.decode(State.self, from: data)
        self.state = decoded
    }

    /// Decodes a `State` value from a JSON string and updates the store.
    ///
    /// See ``updateState(fromJSONData:using:)`` for error behavior.
    ///
    /// - Parameters:
    ///   - jsonString: A UTF-8 JSON string representing `State`.
    ///   - decoder: The decoder to use. Defaults to a new `JSONDecoder`.
    /// - Throws: A decoding error if `jsonString` cannot be decoded as `State`.
    func updateState(fromJSONString jsonString: String,
                     using decoder: JSONDecoder = JSONDecoder()) throws {
        let data = Data(jsonString.utf8)
        try updateState(fromJSONData: data, using: decoder)
    }
}
