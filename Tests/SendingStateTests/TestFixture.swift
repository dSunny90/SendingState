//
//  TestFixture.swift
//  SendingState
//
//  Created by SunSoo Jeon on 23.06.2023.
//

@testable import SendingState

@MainActor enum TestFixture {}

#if os(iOS) || targetEnvironment(macCatalyst)
import UIKit
extension TestFixture {
    static func makeButton(
        tag: Int = 0,
        frame: CGRect = CGRect(x: 0, y: 0, width: 90, height: 44)
    ) -> UIButton {
        let button = UIButton(frame: frame)
        button.tag = tag
        return button
    }

    static func makeSwitch(
        isOn: Bool = false
    ) -> UISwitch {
        let aSwitch = UISwitch()
        aSwitch.isOn = isOn
        return aSwitch
    }

    static func makeSlider(
        value: Float = 0.5,
        range: ClosedRange<Float> = 0...1
    ) -> UISlider {
        let slider = UISlider()
        slider.minimumValue = range.lowerBound
        slider.maximumValue = range.upperBound
        slider.value = value
        return slider
    }

    static func makeView(
        frame: CGRect = CGRect(x: 0, y: 0, width: 128, height: 80)
    ) -> UIView {
        UIView(frame: frame)
    }

    static func makeLabel(
        text: String = "",
        frame: CGRect = CGRect(x: 0, y: 0, width: 100, height: 18)
    ) -> UILabel {
        let label = UILabel(frame: frame)
        label.text = text
        return label
    }

    static func makeTapGesture(
        taps: Int = 1,
        touches: Int = 1
    ) -> UITapGestureRecognizer {
        let gesture = UITapGestureRecognizer()
        gesture.numberOfTapsRequired = taps
        gesture.numberOfTouchesRequired = touches
        return gesture
    }

    static func makePanGesture() -> UIPanGestureRecognizer {
        UIPanGestureRecognizer()
    }

    static func makePinchGesture() -> UIPinchGestureRecognizer {
        UIPinchGestureRecognizer()
    }

    static func makeLongPressGesture(
        minimumDuration: TimeInterval = 0.5
    ) -> UILongPressGestureRecognizer {
        let gesture = UILongPressGestureRecognizer()
        gesture.minimumPressDuration = minimumDuration
        return gesture
    }

    static func makeSwipeGesture(
        direction: UISwipeGestureRecognizer.Direction = .right
    ) -> UISwipeGestureRecognizer {
        let gesture = UISwipeGestureRecognizer()
        gesture.direction = direction
        return gesture
    }
}
#endif
