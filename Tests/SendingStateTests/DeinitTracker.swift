//
//  DeinitTracker.swift
//  SendingState
//
//  Created by SunSoo Jeon on 2023/11/16.
//

/// A class used to track deinit calls.
final class DeinitTracker {
    let onDeinit: () -> Void
    init(onDeinit: @escaping () -> Void) { self.onDeinit = onDeinit }
    deinit { onDeinit() }
}
