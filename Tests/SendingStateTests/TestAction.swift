//
//  TestAction.swift
//  SendingState
//
//  Created by SunSoo Jeon on 23.06.2023.
//

import Foundation

enum TestAction: Equatable, Sendable {
    case buttonTapped(Int)
    case switchChanged(Bool)
    case sliderChanged(Float)
    case sendClickLog
    case viewTapped
    case viewPinched
    case viewPanned
    case longPressed
    case custom(String)
}

extension TestAction {
    var isButtonTap: Bool {
        if case .buttonTapped = self { return true }
        return false
    }

    var isSwitchChange: Bool {
        if case .switchChanged = self { return true }
        return false
    }

    var isSliderChange: Bool {
        if case .sliderChanged = self { return true }
        return false
    }

    var isViewTap: Bool {
        if case .viewTapped = self { return true }
        return false
    }

    func extractButtonTag() -> Int? {
        if case .buttonTapped(let tag) = self {
            return tag
        }
        return nil
    }

    func extractSwitchValue() -> Bool? {
        if case .switchChanged(let value) = self {
            return value
        }
        return nil
    }

    func extractSliderValue() -> Float? {
        if case .sliderChanged(let value) = self {
            return value
        }
        return nil
    }
}
