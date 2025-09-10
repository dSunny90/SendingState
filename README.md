# SendingState

➡️ SendingState is a lightweight Swift framework that helps you cleanly structure UI components around three clear roles: configuring, binding, and forwarding user interactions — all in a one-way flow.

[![SwiftPM compatible](https://img.shields.io/badge/SwiftPM-compatible-brightgreen.svg)](https://swift.org/package-manager/) ![Swift](https://img.shields.io/badge/Swift-5.7-orange.svg) ![Platform](https://img.shields.io/badge/platform-iOS%2012%20%7C%20macOS%2010.13%20%7C%20tvOS%2012%20%7C%20watchOS%204-brightgreen) [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

## Purpose

**SendingState** defines a clean and consistent way for UI components to receive state and forward user interactions — all through a predictable, one-way flow.

It consists of two main flows:

- **🟢 Inbound (Configurable + Boundable)**  
  A component receives a model to configure itself and can optionally be bound to a view model for continuous updates.  
  Once configured, it may **remain bound** to dynamic view model state.  

- **🔴 Outbound (EventForwarder)**  
  User interactions such as taps, gestures are **forwarded outward** as declarative actions.  

When you’re building a data-driven UI in Swift, it’s common to fall into a mix of patterns — configuring views directly, reacting to user events with @IBAction, and juggling internal state inside UI components.
These approaches often work… until your app scales. Then things get messy.

You start to wonder:
- Where should this logic live — in the view, the view controller, or the view model?
- Why does this button action still fire after the view was reused?
- Why are my components holding state they shouldn’t?

**SendingState** is a minimal set of conventions to bring structure and clarity to this chaos.
It gives every component a clean way to receive state, bind view models, and forward user intent — all in a one-way, predictable flow.

Because it’s all about **sending**.

- Sending model to a view (configure)
- Sending viewModel to a view (bind)
- Sending user events back (forward)

Think of it as the unidirectional pipeline for your component logic

Let’s take a closer look at what usually goes wrong when we mix UI, state, and logic without clear boundaries.

### 💣 The Usual UI Chaos

#### Business logic inside UI selectors

```swift
@objc func didTapConfirmButton(_ sender: UIButton) {
    guard user.isVerified else {
        showVerificationAlert()
        return
    }

    viewModel.proceedToNextStep(userID: user.id)
}
```

- UI events are tightly coupled with application logic
- No clear separation between input and processing
- Hard to test, reuse, or refactor independently

#### Gesture handling with scattered selectors

```swift
@objc func handleTap() {
    self.tapGestureClosure?()
}

@objc func didTapButton(_ sender: UIButton) {
    self.didTapClosure?(sender)
}
```

- Event logic is spread across multiple methods with no clear structure
- Hard to trace which UI triggers which action
- Adds complexity as gestures and selectors grow

#### Configurations that mutate passed-in state

```swift
class MyCell: UITableViewCell {
    private var data: MyData?

    func configure(_ data: MyData?) {
        self.data = data
        titleLabel.text = data?.title
        // also updates imageView, buttons, etc.
    }

    func changeData() {
        self.data?.title = "error"
    }
}
```

- Stores and mutates input state internally
- Breaks one-way data flow principles
- Introduces side effects and hidden state changes

### 🛠️ With **SendingState**

#### Forward Events, Handle Actions in the Interactor

```swift
class MyCell: UITableViewCell, EventForwardingProvider {
    var eventForwarder: EventForwardable {
        SenderGroup {
            EventForwarder(button) { sender, ctx in
                ctx.control([.touchUpInside]) {
                    [MyAction.sendClickLog, .applyFilter(sender.tag)]
                }
            }
            EventForwarder(aView) { _, ctx in
                ctx.tapGesture() { [MyAction.sendClickLog] }
            }
            EventForwarder(slider) { sender, ctx in
                ctx.control(.valueChanged) {
                    [MyAction.sendClickLog, .changeSlider(sender.value)]
                }
            }
        }
    }
}

class MyInteractor: NSObject, ActionHandlingProvider {
    func handle(action: MyAction) {
        switch action {
        case .sendClickLog:
            // send click log
        case .applyFilter(let tag):
            // apply filter
        case .changeSlider(let value):
            // change slider
        }
    }
}
```

- **Declarative event mapping** – Define all UI events clearly and locally
- **Clear separation of view and logic** – Views forward, Interactor handles
- **Scalable and testable structure** – Add actions without touching the UI

#### Stateless configuration

```swift
class MyView: UIView, Configurable {
    var configurer: (MyView, MyModel) -> Void {
        { view, model in
            view.titleLabel.text = model.title
        }
    }
}

class MyViewController: UIViewController {
    func updateUI(with data: MyModel) {
        myView.ss.configure(data)
    }
}
```
- **No internal state mutation** – The view doesn’t store or alter the model internally
- **Unidirectional data flow** – Data goes in via configure, no implicit feedback loop
- **Decoupled and testable UI** – View logic is stateless and easy to verify

#### Safe binding

```swift
class MyViewController: UIViewController {
    func bindViewModel(with viewModel: MyViewModel) {
        viewModel.bound(to: myView)
    }
}
```

- **One-way binding from logic to view** – ViewModel updates the view, not the other way around
- **No retained or leaked state in the view** – View remains stateless and passive
- **Easy to compose and replace view logic** – ViewModel controls flow without modifying UI internals

Let the code guide you — just follow me.

---

## Usage

### Configurable:

1. Adopt the Configurable protocol in your view.
2. Implement the configurer to define how the view should be updated with a model.
3. Call `aView.ss.configure(model)` whenever you want to apply new data — that’s it.

The data flows in one direction only — from model to view.
No need to capture self or worry about memory leaks — all closures are safely handled.

### Boundable:

1. After adopting Configurable, conform your view to Boundable.
2. Implement the binding logic so your ViewModel can update the view reactively.
3. Use `viewModel.bound(to: view)` to connect the two.

Want to drive a collection of views from an array of data?
Use AnyBoundable to erase the types and bind them in a loop — no type gymnastics, just clean bindings.

### EventForwarder:

1. In views that handle user input (like a UIButton or UIView with a gesture), conform to EventForwardingProvider.
2. Use EventForwarder blocks to declare which events trigger which actions.
3. In your viewController or interactor, conform to ActionHandlingProvider and handle actions centrally.
4. Use `aView.ss.assignActionHandler(to: self.interactor)` to prepare for forwarding events.
    
And just like that — your business logic is cleanly separated and elegantly handled.

## Swift 6 Migration

> **Background.** SendingState was originally designed in 2020, prior to Swift’s structured concurrency. When using it in a Swift 6 / strict-concurrency environment, follow these guidelines.

### 1) `Configurable` (UIKit views/cells)

For UI types (e.g., `UITableViewCell`, `UIView`) that adopt `Configurable`, do one of the following:

**A. Pre-concurrency conformance (easiest for migration)**

```swift
// (1) Optionally soften concurrency checks for this import
@preconcurrency import SendingState

// (2) Mark the *conformance* as preconcurrency
public final class MyCell: UITableViewCell, @preconcurrency Configurable {
    var configurer: (MyCell, MyModel) -> Void {
        { view, model in
            view.label.text = model.text
            view.label.font = UIFont.systemFont(ofSize: model.fontSize)
        }
    }
}
```

**B. Actor-aware conformance (preferred long-term)**

Expose a `nonisolated` configurer and hop to MainActor inside the closure.

```swift
@MainActor
public final class MyCell: UITableViewCell, Configurable {
    // Keep UI work on the main actor:
    nonisolated var configurer: (MyCell, MyModel) -> Void {
        { view, model in
            Task { @MainActor in
                view.label.text = model.text
                view.label.font = UIFont.systemFont(ofSize: model.fontSize)
            }
        }
    }
}
```

> Why: nonisolated allows callers to obtain and invoke configurer without an implicit hop, while the body still updates UI safely on MainActor.

### 2) `Boundable` (now Sendable)

Because `Boundable` conforms to Sendable, a class-based ViewModel must ensure thread safety. If you keep it as a class, declare `@unchecked Sendable` and protect all mutable state (e.g., with NSLock). Avoid storing UI objects inside.

```swift
public final class MyViewModel: @unchecked Sendable, Boundable {
    public var contentData: MyModel? {
        get { lock.lock(); defer { lock.unlock() }; return _contentData }
        set { lock.lock(); _contentData = newValue; lock.unlock() }
    }

    private let lock = NSLock()
    private var _contentData: MyModel?
}
```

Alternative (recommended when possible): make the ViewModel a struct (value type) so Sendable is automatic and locks aren’t needed, or wrap shared mutable state in an actor.

---

## Installation

SendingState is available via Swift Package Manager.

### Using Xcode:

1. Open your project in Xcode
2. Go to File > Add Packages…
3. Enter the URL:  
```
https://github.com/dSunny90/SendingState
```
4. Select the version and finish

### Using Package.swift:
```swift
dependencies: [
    .package(url: "https://github.com/dSunny90/SendingState", from: "1.0.1")
]
```
