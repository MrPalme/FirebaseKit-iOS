//
//  FirebaseKitStringProviding.swift
//  FirebaseKit
//
//  Created by Markus Mock on 22.02.26.
//

import Foundation

/// Keys for user-facing strings that FirebaseKit may surface through errors
/// or state descriptions. Host apps can override any of these via a custom
/// ``FirebaseKitStringProviding`` implementation.
public enum FirebaseKitStringKey: String, Sendable, CaseIterable {
    // Auth
    case authSignInFailed = "auth.signIn.failed"
    case authSignOutFailed = "auth.signOut.failed"
    case authInvalidCredentials = "auth.invalidCredentials"
    case authUserNotFound = "auth.userNotFound"
    case authEmailAlreadyInUse = "auth.emailAlreadyInUse"
    case authWeakPassword = "auth.weakPassword"
    case authSessionExpired = "auth.sessionExpired"

    // Remote Config
    case remoteConfigFetchFailed = "remoteConfig.fetchFailed"
    case remoteConfigThrottled = "remoteConfig.throttled"

    // Messaging
    case messagingTokenFailed = "messaging.tokenFailed"

    // Firestore
    case firestoreDocumentNotFound = "firestore.documentNotFound"
    case firestoreOperationFailed = "firestore.operationFailed"

    // General
    case unknownError = "general.unknownError"
}

/// A protocol for providing localized strings used by FirebaseKit.
///
/// Implement this protocol and inject it via ``FirebaseKitConfiguration/stringProvider``
/// to override the default English strings with your own translations.
///
/// ```swift
/// struct AppStringsProvider: FirebaseKitStringProviding {
///     func string(_ key: FirebaseKitStringKey) -> String {
///         NSLocalizedString(key.rawValue, bundle: .main, comment: "")
///     }
/// }
/// ```
public protocol FirebaseKitStringProviding: Sendable {

    /// Returns the localized string for the given key.
    ///
    /// - Parameter key: The string key to resolve.
    /// - Returns: A user-facing string.
    func string(_ key: FirebaseKitStringKey) -> String
}

/// Default English strings shipped with FirebaseKit.
///
/// When no custom ``FirebaseKitStringProviding`` is injected, these strings
/// are used for any user-facing messages.
public struct FirebaseKitDefaultStrings: FirebaseKitStringProviding {

    public init() {}

    public func string(_ key: FirebaseKitStringKey) -> String {
        switch key {
        case .authSignInFailed:
            return "Sign-in failed. Please try again."
        case .authSignOutFailed:
            return "Sign-out failed. Please try again."
        case .authInvalidCredentials:
            return "Invalid email or password."
        case .authUserNotFound:
            return "No account found with this email."
        case .authEmailAlreadyInUse:
            return "An account with this email already exists."
        case .authWeakPassword:
            return "Password is too weak. Please choose a stronger password."
        case .authSessionExpired:
            return "Your session has expired. Please sign in again."
        case .remoteConfigFetchFailed:
            return "Failed to fetch remote configuration."
        case .remoteConfigThrottled:
            return "Configuration updates are temporarily unavailable."
        case .messagingTokenFailed:
            return "Failed to register for push notifications."
        case .firestoreDocumentNotFound:
            return "The requested document was not found."
        case .firestoreOperationFailed:
            return "A database operation failed. Please try again."
        case .unknownError:
            return "An unexpected error occurred."
        }
    }
}
