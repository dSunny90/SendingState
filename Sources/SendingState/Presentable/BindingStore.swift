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
    : Presentable where Binder.Input == State
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
