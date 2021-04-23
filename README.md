# SendingState

➡️ SendingState is a lightweight Swift framework that helps you cleanly structure UI components

[![SwiftPM compatible](https://img.shields.io/badge/SwiftPM-compatible-brightgreen.svg)](https://swift.org/package-manager/) ![Swift](https://img.shields.io/badge/Swift-5.0-orange.svg) ![Platform](https://img.shields.io/badge/platform-iOS%208%20%7C%20macOS%2010.10%20%7C%20tvOS%209%20%7C%20watchOS%202-brightgreen) [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

## Purpose

**SendingState** provides a consistent pattern for UI components to receive state and forward user interactions through unidirectional data flow.

- **Configurable**  
  Components receive models for configuration.

- **Bindable**  
  View models deliver state snapshots to views through one-way binding.
  
- **EventSendable**  
    User interactions are forwarded as declarative actions.

---

When building data-driven UIs in Swift, it's common to fall into a mix of patterns — configuring views directly, reacting to user events with @IBAction, and juggling internal state inside UI components. These approaches often work… until your app scales. Then things get messy.

**SendingState** gives every component a clear way to receive state, bind view models, and forward user intent through a unidirectional pipeline.

The name reflects its core principle:

- **Send** models to views (configure)
- **Send** view models to views (bind)
- **Send** user events back (forward)

Let's look at what typically goes wrong when we mix UI, state, and logic without clear boundaries.

### 💣 The Usual UI Chaos

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

### Bindable:

1. After adopting `Configurable`, conform your view model to `Bindable`
2. Implement the binding logic so your view model can deliver state to the view
3. Use `viewModel.apply(to: view)` to apply the state

For collections of views driven by arrays of data, use `AnyBindable` to erase types and bind them in a loop — no type gymnastics required.

### EventSendable:

1. In views that handle user input (buttons, views with gestures), conform to `EventSendingProvider`
2. Use `EventForwarder` blocks to declare which events trigger which actions
3. In your view controller or interactor, conform to `ActionHandlingProvider` and handle actions centrally
4. Use `aView.ss.addActionHandler(to: self.interactor)` to connect the flow
    
Your business logic is now cleanly separated and elegantly handled.

### State:

When you call `ss.configure(model)`, the model is automatically stored as **state** on the view.
If you need the model data, just read it from `self.ss.state()` — there’s no need to store it separately.

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
    .package(url: "https://github.com/dSunny90/SendingState", from: "0.3.0")
]
```
