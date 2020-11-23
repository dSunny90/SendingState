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
///
/// Adopting this protocol allows you to:
/// - Pass state or view models explicitly without storing them
/// - Avoid retain cycles without capturing `self` strongly inside `configurer`
/// - Separate configuration logic from state ownership
/// - Focus on presentation logic
///
/// By associating a specific input type with a concrete view or object,
/// this protocol reduces type casting and boilerplate
/// while making configuration type-safe and intuitive.
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
/// ```
public protocol Configurable: AnyObject {
    associatedtype Input
    /// A closure that applies an input to update the receiver.
    ///
    /// The `configurer` defines how `Self` responds to a given `Input`.
    var configurer: (Self, Input) -> Void { get }

    /// Returns the preferred size for the component based on the provided input
    /// and optional parent constraint.
    ///
    /// - Parameters:
    ///   - input: Data used to determine the preferred size.
    ///   - parentSize: An optional size constraint from the parent container.
    /// - Returns: The estimated size required to display the input,
    ///            or `nil` if no size calculation is needed.
    static func size(with input: Input?,
                     constrainedTo parentSize: CGSize?) -> CGSize?
}

public extension Configurable {
    static func size(with input: Input?,
                     constrainedTo parentSize: CGSize?) -> CGSize? {
        return nil
    }
}
