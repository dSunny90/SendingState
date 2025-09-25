//
//  DeinitTracker.swift
//  SendingState
//
//  Created by SunSoo Jeon on 25.09.2025.
//

/// A class used to track deinit calls.
final class DeinitTracker {
    let onDeinit: () -> Void
    init(onDeinit: @escaping () -> Void) { self.onDeinit = onDeinit }
    deinit { onDeinit() }
}
