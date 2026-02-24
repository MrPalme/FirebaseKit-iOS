//
//  FirebaseKitEnvironment.swift
//  FirebaseKit
//
//  Created by Markus Mock on 22.02.26.
//

import Foundation

/// Represents the runtime environment for the host application.
///
/// The environment is set once during ``FirebaseKit/configure(_:)`` and can
/// influence service behavior such as Remote Config fetch intervals or
/// logging verbosity.
public enum FirebaseKitEnvironment: String, Sendable {
    /// Local development.
    case debug
    /// Pre-production / QA testing.
    case staging
    /// Live / production.
    case production
}
