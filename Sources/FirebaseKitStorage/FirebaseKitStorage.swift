//
//  FirebaseKitStoragePlaceholder.swift
//  FirebaseKit
//
//  Created by Markus Mock on 22.02.26.
//

import Foundation
import FirebaseStorage
import FirebaseKitCore

// MARK: - Placeholder

/// Placeholder module for Firebase Storage integration.
///
/// This module is scaffolded but not implemented. A future version will
/// provide a ``FirebaseKitStorageServing`` protocol and concrete service
/// for upload, download, and metadata operations.
///
/// Register pattern will follow the same convention:
/// ```swift
/// try FirebaseKit.configure(config)
/// FirebaseKitStorageService.register()
/// ```
public enum FirebaseKitStoragePlaceholder {
    /// Module identifier.
    public static let moduleName = "FirebaseKitStorage"
}
