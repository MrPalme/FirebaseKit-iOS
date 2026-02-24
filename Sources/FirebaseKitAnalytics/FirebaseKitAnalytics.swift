//
//  FirebaseKitAnalyticsPlaceholder.swift
//  FirebaseKit
//
//  Created by Markus Mock on 22.02.26.
//

import Foundation
import FirebaseAnalytics
import FirebaseKitCore

// MARK: - Placeholder

/// Placeholder module for Firebase Analytics integration.
///
/// This module is scaffolded but not implemented. A future version will
/// provide a ``FirebaseKitAnalyticsServing`` protocol and concrete service
/// for event logging and user property management.
///
/// Register pattern will follow the same convention:
/// ```swift
/// try FirebaseKit.configure(config)
/// FirebaseKitAnalyticsService.register()
/// ```
public enum FirebaseKitAnalyticsPlaceholder {
    /// Module identifier.
    public static let moduleName = "FirebaseKitAnalytics"
}
