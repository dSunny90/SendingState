//
//  TestBoundableViewModel.swift
//  SendingState
//
//  Created by SunSoo Jeon on 01.02.2021.
//

@testable import SendingState

#if os(iOS) || targetEnvironment(macCatalyst)
import UIKit

struct TestBoundableViewModel: Boundable {
    var contentData: TestConfigurableUIView.Model?
    var binderType: TestConfigurableUIView.Type { TestConfigurableUIView.self }

    init(contentData: TestConfigurableUIView.Model? = nil) {
        self.contentData = contentData
    }
}
#endif
