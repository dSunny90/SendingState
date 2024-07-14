//
//  TestClassInputConfigurableUIView.swift
//  SendingState
//
//  Created by SunSoo Jeon on 26.06.2023.
//

@testable import SendingState

#if os(iOS) || targetEnvironment(macCatalyst)
import UIKit

/// A Configurable UIView that accepts class (DeinitTracker) input.
@MainActor
final class TestClassInputConfigurableUIView: UIView, Configurable {
    var configurer: (TestClassInputConfigurableUIView, DeinitTracker) -> Void {
        { _, _ in }
    }
}

#endif
