//
//  TestActionTrigger.swift
//  SendingState
//
//  Created by SunSoo Jeon on 23.06.2023.
//

import ObjectiveC.runtime
@testable import SendingState

enum TestActionTrigger {}

#if os(iOS) || targetEnvironment(macCatalyst)
import UIKit
extension TestActionTrigger {
    // MARK: - UIControl Triggers

    static func simulateControl(_ control: UIControl, for event: UIControl.Event) {
        for target in control.allTargets {
            guard let actions = control.actions(forTarget: target, forControlEvent: event) else { continue }

            for actionName in actions {
                let selector = Selector(actionName)
                invoke(target: target as AnyObject, selector: selector, sender: control)
            }
        }
    }

    static func simulateSwitch(_ control: UISwitch, flag: Bool) {
        let oldValue = control.isOn
        control.isOn = flag

        for target in control.allTargets {
            guard let actions = control.actions(forTarget: target, forControlEvent: .valueChanged) else { continue }

            for actionName in actions where oldValue != flag {
                let selector = Selector(actionName)
                invoke(target: target as AnyObject, selector: selector, sender: control)
            }
        }
    }

    static func simulateSlider(_ control: UISlider, value: Float) {
        let oldValue = control.value
        control.value = value

        for target in control.allTargets {
            guard let actions = control.actions(forTarget: target, forControlEvent: .valueChanged) else { continue }

            for actionName in actions where oldValue != value {
                let selector = Selector(actionName)
                invoke(target: target as AnyObject, selector: selector, sender: control)
            }
        }
    }

    static func simulateTextField(_ control: UITextField, text: String? = nil) {
        let oldValue = control.text
        control.text = text

        for target in control.allTargets {
            guard let actions = control.actions(forTarget: target, forControlEvent: .editingChanged) else { continue }

            for actionName in actions where oldValue != text {
                let selector = Selector(actionName)
                invoke(target: target as AnyObject, selector: selector, sender: control)
            }
        }
    }

    // MARK: - Gesture Triggers (via SenderEventBox)

    /// Simulates a gesture recognition by invoking the target's invoke method directly.
    static func simulateGestureRecognition(
        _ gesture: UIGestureRecognizer
    ) {
        // Use KVC to access private targets array
        if let targets = gesture.value(forKey: "targets") as? [AnyObject] {
            for target in targets {
                if let box = target.value(forKey: "target") as? UIGestureRecognizerSenderEventBox {
                    box.box?(gesture)
                }
            }
        }
    }

    private static func invoke(target: AnyObject, selector: Selector, sender: UIView) {
        guard target.responds(to: selector) else { return }
        guard let method = class_getInstanceMethod(object_getClass(target), selector) else { return }

        let argCount = method_getNumberOfArguments(method)

        typealias Action0 = @convention(c) (AnyObject, Selector) -> Void
        typealias Action1 = @convention(c) (AnyObject, Selector, AnyObject) -> Void

        let imp = method_getImplementation(method)

        switch argCount {
        case 2:
            let f = unsafeBitCast(imp, to: Action0.self)
            f(target, selector)

        case 3:
            let f = unsafeBitCast(imp, to: Action1.self)
            f(target, selector, sender)

        default:
            break
        }
    }
}
#endif
