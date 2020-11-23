# SendingState

➡️ SendingState is a lightweight Swift framework that helps you cleanly structure UI components

[![SwiftPM compatible](https://img.shields.io/badge/SwiftPM-compatible-brightgreen.svg)](https://swift.org/package-manager/) ![Swift](https://img.shields.io/badge/Swift-5.0-orange.svg) ![Platform](https://img.shields.io/badge/platform-iOS%208%20%7C%20macOS%2010.10%20%7C%20tvOS%209%20%7C%20watchOS%202-brightgreen) [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

## Purpose

- **Configurable**  
  A component receives a model to configure itself

When you’re building a data-driven UI in Swift, it’s common to fall into a mix of patterns — configuring views directly and juggling internal state inside UI components.
These approaches often work… until your app scales. Then things get messy.

**SendingState** is a minimal set of conventions to bring structure and clarity to this chaos.
It gives every component a clean way to receive state.

Because it’s all about **sending**.

- Sending model to a view (configure)

Think of it as the unidirectional pipeline for your component logic

Let’s take a closer look at what usually goes wrong when we mix UI, state, and logic without clear boundaries.

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

- Stores and mutates input state internally
- Breaks one-way data flow principles
- Introduces side effects and hidden state changes

### 🛠️ With **Configurable**

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

---

## Usage

### Configurable:

1. Adopt the Configurable protocol in your view.
2. Implement the configurer to define how the view should be updated with a model.
3. Call `aView.ss.configure(model)` whenever you want to apply new data — that’s it.

The data flows in one direction only — from model to view.
No need to capture self or worry about memory leaks — all closures are safely handled.

---

## Installation

SendingState is available via Swift Package Manager.

### Using Xcode:

1. Open your project in Xcode
2. Go to File > Add Packages…
3. Enter the URL:  
```
https://github.com/dsunny90/SendingState
```
4. Select the version and finish

### Using Package.swift:
```swift
dependencies: [
    .package(url: "https://github.com/dsunny90/SendingState", from: "0.1.0")
]
```
