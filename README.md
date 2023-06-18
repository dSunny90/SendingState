# SendingState

➡️ SendingState is a lightweight Swift framework that helps you cleanly structure UI components around three clear roles: configuring, binding, and forwarding user interactions — all in a predictable, one-way flow.

[![SwiftPM compatible](https://img.shields.io/badge/SwiftPM-compatible-brightgreen.svg)](https://swift.org/package-manager/) ![Swift](https://img.shields.io/badge/Swift-5.7-orange.svg) ![Platform](https://img.shields.io/badge/platform-iOS%2012%20%7C%20macOS%2010.13%20%7C%20tvOS%2012%20%7C%20watchOS%204-brightgreen) [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

## Purpose

**SendingState** provides a consistent pattern for UI components to receive state and forward user interactions through unidirectional data flow.

- **Configurable**  
  Components receive models for configuration.

- **Boundable**  
  View models deliver state snapshots to views through one-way binding.
  
- **EventForwarder**  
  User interactions are forwarded as declarative actions. Action closures can access the bound state directly — no manual state passing needed.

---

When building data-driven UIs in Swift, it's common to fall into a mix of patterns — configuring views directly, reacting to user events with @IBAction, and juggling internal state inside UI components. These approaches often work… until your app scales. Then things get messy.

**SendingState** gives every component a clear way to receive state, bind view models, and forward user intent through a unidirectional pipeline.

The name reflects its core principle:

- **Send** models to views (configure)
- **Send** view models to views (bind)
- **Send** user events back (forward)

Let's look at what typically goes wrong when we mix UI, state, and logic without clear boundaries.

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

#### Problems:

- UI events are tightly coupled with application logic
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

#### Problems:

- Event logic is spread across multiple methods
- Hard to trace which UI triggers which action

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

#### Problems:

- Stores and mutates input state internally
- Breaks unidirectional data flow
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

#### Benefits:

- Declarative event mapping with clear local definitions
- Views forward events, interactors handle logic
- Easy to add actions without touching UI code

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

#### Benefits:

- No internal state mutation
- Clear unidirectional data flow
- Decoupled and testable UI components

#### Safe binding

```swift
class MyViewController: UIViewController {
    func bindViewModel(with viewModel: MyViewModel) {
        viewModel.apply(to: myView)
    }
}
```

#### Benefits:

- View models control updates without modifying UI internals
- No retained or leaked state in views
- Easy to compose and swap view logic

---

## Usage

### Configurable:

1. Adopt the `Configurable` protocol in your view
2. Implement the **configurer** to define how the view updates with a model
3. Call `aView.ss.configure(model)` whenever you want to apply new data

The data flows in one direction only — from model to view.
No need to capture self or worry about memory leaks — all closures are safely handled.

### Boundable:

1. After adopting `Configurable`, conform your view model to `Boundable`
2. Implement the binding logic so your view model can deliver state to the view
3. Use `viewModel.apply(to: view)` to apply the state

For collections of views driven by arrays of data, use `AnyBoundable` to erase types and bind them in a loop — no type gymnastics required.

### EventForwardable:

1. In views that handle user input (buttons, views with gestures), conform to `EventForwardingProvider`
2. Use `EventForwarder` blocks to declare which events trigger which actions
3. In your view controller or interactor, conform to `ActionHandlingProvider` and handle actions centrally
4. Use `aView.ss.addActionHandler(to: self.interactor)` to connect the flow
    
Your business logic is now cleanly separated and elegantly handled.

### State:

When you call `ss.configure(model)`, the model is automatically stored as **state** on both the view and all its senders (buttons, switches, etc.). This means your `EventForwarder` closures can access the configured data at event time — no manual state passing required.

#### Accessing state

On binder (Configurable) — the compiler infers the `Input` type automatically:

```swift
let model = cell.ss.state()  // → MyModel?
```

On sender (UIButton, etc.) — type annotation required:

```swift
let model: MyModel? = button.ss.state()
```

#### State-aware EventForwarder

Instead of manually calling `sender.ss.state()` inside closures, use the **state-aware overload** to receive typed state directly as a closure parameter:

```swift
class MyCell: UITableViewCell, Configurable, EventForwardingProvider {
    let button = UIButton()

    var configurer: (MyCell, MyModel) -> Void {
        { cell, model in
            DispatchQueue.main.async {
                cell.button.setTitle(model.title, for: .normal)
            }
        }
    }

    var eventForwarder: EventForwardable {
        EventForwarder(button) { _, ctx in
            ctx.control(.touchUpInside) { (state: MyModel) in
                [MyAction.buttonTapped(state.id)]
            }
        }
    }
}
```

The state is resolved lazily at **event time** (when the user taps the button), not at setup time. This means it always reflects the latest configured model — even after cell reuse with new data.

All `SenderEventMappingContext` methods support both signatures:

```swift
// Without state — captures sender directly
ctx.control(.touchUpInside) {
    [MyAction.buttonTapped(sender.tag)]
}

// With state — receives typed model from boundState
ctx.control(.touchUpInside) { (state: MyModel) in
    [MyAction.buttonTapped(state.id)]
}
```

This also works with gesture mappings: `tapGesture`, `longPressGesture`, `swipeGesture`, `panGesture`, `pinchGesture`, `rotationGesture`, `screenEdgeGesture`, and `hoverGesture`.

#### Type-Erased Handler with `attach(to:)` / `detach(from:)`

When working with reusable cells (e.g. `UICollectionView`, `UITableView`), you often don't know the concrete cell type at the point of handler attachment. `AnyActionHandlingProvider` wraps any typed handler into a type-erased form, and its `attach(to:)` / `detach(from:)` instance methods solve the Swift existential limitation that prevents calling `view.ss.addAnyActionHandler(to:)` through a protocol composition existential.

```swift
// Wrap your typed handler once
let actionHandler = AnyActionHandlingProvider(interactor)

// In cellForItemAt — safe to call repeatedly on reused cells
func collectionView(_ collectionView: UICollectionView,
                    cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(
        withReuseIdentifier: identifier, for: indexPath
    )
    item.apply(to: cell)

    if let aCell = cell as? (UIView & EventForwardingProvider) {
        actionHandler.attach(to: aCell)
    }
    return cell
}
```

- **Idempotent** — calling `attach(to:)` multiple times on the same cell has no additional effect; no duplicate handlers accumulate
- **Existential-safe** — the generic parameter opens the existential type, bypassing Swift's limitation where `any UIView & EventForwardingProvider` cannot satisfy `Base: UIView & EventForwardingProvider`
- **Symmetric API** — use `detach(from:)` to remove the handler when needed

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
    .package(url: "https://github.com/dSunny90/SendingState", from: "0.5.0")
]
```
