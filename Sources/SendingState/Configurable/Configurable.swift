//
//  Configurable.swift
//  SendingState
//
//  Created by SunSoo Jeon on 23.11.2020.
//

import CoreGraphics

/// A protocol for objects that can be configured with a typed input.
///
/// Use `configurer` to define how the object responds to a given `Input`,
/// such as a view model or rendering state.
/// Calling `configure(_:)` applies that input to the object.
///
/// Adopting this protocol allows you to:
/// - Pass state or view model explicitly, without storing it.
/// - Avoid retain cycles by not strongly capturing `self` inside `configurer`.
/// - Separate configuration logic from state ownership.
/// - Focus solely on how to present the state.
///
/// By tying a specific input type to a concrete view or object,
/// this protocol reduces type casting and boilerplate,
/// and makes configuration type-safe and intuitive.
///
/// ### Example:
/// ```swift
/// class MyCell: UICollectionViewCell, Configurable {
///     @IBOutlet weak var myLabel: UILabel!
///     var configurer: ((MyCell, MyViewModel) -> Void) {
///         { view, viewModel in
///             DispatchQueue.main.async {
///                 view.myLabel.text = viewModel.title
///             }
///         }
///     }
/// }
///

public protocol Configurable: AnyObject {
    associatedtype Input
    /// A closure that applies the input to update the receiver.
    ///
    /// The `configurer` defines how `Self` responds to the given `Input`.
    /// Call `ss.configure(_:)` to apply the configuration.
    var configurer: (Self, Input) -> Void { get }

    /// Returns a size for the component based on the provided input
    /// and optional parent constraint.
    ///
    /// - Parameters:
    ///   - input: Data used to determine the preferred size.
    ///   - parentSize: Optional size constraint from the parent container.
    /// - Returns: The estimated size the component needs to display the input.
    static func size(with input: Input?,
                     constrainedTo parentSize: CGSize?) -> CGSize?
}

public extension Configurable {
    static func size(with input: Input?,
                     constrainedTo parentSize: CGSize?) -> CGSize? {
        return nil
    }
}
