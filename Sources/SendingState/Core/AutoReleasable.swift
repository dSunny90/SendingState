//
//  AutoReleasable.swift
//  SendingState
//
//  Created by SunSoo Jeon on 24.03.2021.
//

/// A protocol for objects that can explicitly release resources
/// when no longer needed.
///
/// - Note: This protocol is primarily used for releasing resources
///   retained by system frameworks such as UIKit or AppKit
///   (e.g., gesture recognizers, control event targets).
internal protocol AutoReleasable: AnyObject {
    /// An optional identifier for the owner of this resource.
    ///
    /// Used to group and remove related resources together.
    var ownerIdentifier: ObjectIdentifier? { get set }

    /// Releases retained resources explicitly.
    func cleanup()
}
