//
//  TestBoundableModel.swift
//  SendingState
//
//  Created by SunSoo Jeon on 01.02.2021.
//

import Foundation
@testable import SendingState

struct TestBoundableModel: Boundable {
    var contentData: String?
    var binderType: TestConfigurableObject.Type { TestConfigurableObject.self }

    init(contentData: String? = nil) {
        self.contentData = contentData
    }
}
