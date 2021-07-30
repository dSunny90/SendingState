//
//  AutoReleasable.swift
//  SendingState
//
//  Created by SunSoo Jeon on 30.07.2021.
//

/// A protocol representing an object that can be explicitly cleaned up
/// when no longer needed, typically as part of memory management.
///
/// Types conforming to `AutoReleasable` are meant to be retained in a
/// `SwiftPointerPool` and are expected to release their internal resources
/// (e.g. gesture recognizer targets, control event handlers) in `cleanup()`.
///
/// - Note: This protocol is mainly used to release resources that are
///   retained by system frameworks such as UIKit or AppKit (e.g.,
///   gesture recognizers, control event targets).
internal protocol AutoReleasable: AnyObject {
    /// Called to explicitly release retained resources.
    /// This will be triggered by a `SwiftPointerPool` when it is deallocated.
    func cleanup()
}
