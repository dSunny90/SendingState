//
//  TestClosureConfigurableUIView.swift
//  SendingState
//
//  Created by SunSoo Jeon on 23.06.2023.
//

@testable import SendingState

#if os(iOS) || targetEnvironment(macCatalyst)
import UIKit

/// A Configurable UIView that exposes a closure for configurer invocation counting.
@MainActor
final class TestClosureConfigurableUIView: UIView, Configurable {
    private let callback: () -> Void

    var configurer: (TestClosureConfigurableUIView, String) -> Void {
        { view, _ in
            view.callback()
        }
    }

    init(callback: @escaping () -> Void) {
        self.callback = callback
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

#endif
