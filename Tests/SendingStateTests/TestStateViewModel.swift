//
//  TestStateViewModel.swift
//  SendingState
//
//  Created by SunSoo Jeon on 23.06.2023.
//

@testable import SendingState

#if os(iOS) || targetEnvironment(macCatalyst)
import UIKit

/// Boundable for TestStateUIView.
struct TestStateViewModel: Boundable {
    var contentData: TestConfigurableUIView.Model?
    var binderType: TestStateUIView.Type { TestStateUIView.self }
}

#endif
