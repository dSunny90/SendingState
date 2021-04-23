# SendingState

➡️ SendingState is a lightweight Swift framework that helps you cleanly structure UI components

[![SwiftPM compatible](https://img.shields.io/badge/SwiftPM-compatible-brightgreen.svg)](https://swift.org/package-manager/) ![Swift](https://img.shields.io/badge/Swift-5.0-orange.svg) ![Platform](https://img.shields.io/badge/platform-iOS%208%20%7C%20macOS%2010.10%20%7C%20tvOS%209%20%7C%20watchOS%202-brightgreen) [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

## Purpose

- **Configurable**  
  Components receive models for configuration.

- **Presentable**  
  Components expose current state and apply it to binders.
  
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

### 💣 Views that mutate their own state

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

### 💣 Models and UI that fall out of sync

```swift
class MyViewController: UIViewController {
    private var currentData: MyModel?

    func configure(_ data: MyModel) {
        currentData = data
        myView.ss.configure(data)
    }

    // Manually sync changes back from the view
    func viewDidUpdate(_ updated: MyModel) {
        currentData = updated
        notifyParent(updated)
    }
}
```

#### Problems:

- Easy to get out of sync when multiple views share the same data
- Boilerplate grows fast as state gets more complex

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

#### Automatic model-UI synchronization

```swift
class MyViewController: UIViewController {
    private let store = BindingStore(contentData: MyModel())
    private var token: StateObservationToken?

    override func viewDidLoad() {
        super.viewDidLoad()

        store.apply(to: myView)

        token = store.observe { [weak self] updated in
            // always in sync — no manual wiring needed
            self?.handleUpdate(updated)
        }
    }
}
```

#### Benefits:

- Changes from the view are written back into the store
- Clean observation API with automatic lifetime management via `StateObservationToken`

---

## Usage

### Configurable:

1. Adopt the `Configurable` protocol in your view
2. Implement the **configurer** to define how the view updates with a model
3. Call `aView.ss.configure(model)` whenever you want to apply new data

The data flows in one direction only — from model to view.
No need to capture self or worry about memory leaks — all closures are safely handled.

### Presentable:

Sometimes rendering alone is not enough.  
A component may need to hold its current state and apply that state to a binder.

`Presentable` models that relationship.

1. Expose the current `state`
2. Implement `apply(to:)` to present that state to a binder
3. Use it when the relationship between state and binder needs to be enforced by the type system

`BindingStore` is a ready-made implementation of `Presentable` — it holds the current state, applies it to a binder, and notifies observers whenever that state changes.

You can implement `Presentable` directly for custom state holders, but if you also need observation, `BindingStore` is the natural starting point.

When you need to store heterogeneous `BindingStore` instances in a single collection, use `AnyBindingStore` to erase the concrete type — similar to how `AnyKeyPath` erases a key path's root and value types.

### EventSendable:

1. In views that handle user input (buttons, views with gestures), conform to `EventSendingProvider`
2. Use `EventForwarder` blocks to declare which events trigger which actions
3. In your view controller or interactor, conform to `ActionHandlingProvider` and handle actions centrally
4. Use `aView.ss.addActionHandler(to: self.interactor)` to connect the flow
    
Your business logic is now cleanly separated and elegantly handled.

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
    .package(url: "https://github.com/dSunny90/SendingState", from: "0.1.0")
]
```
