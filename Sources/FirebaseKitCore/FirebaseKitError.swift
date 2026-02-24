//
//  FirebaseKitError.swift
//  FirebaseKit
//
//  Created by Markus Mock on 22.02.26.
//

import Foundation

/// Unified error type for all FirebaseKit modules.
///
/// Each case carries an ``underlying`` error that preserves the original
/// Firebase SDK error for debugging while exposing a stable domain category
/// the host app can match on without depending on Firebase error codes directly.
public enum FirebaseKitError: Error, Sendable {

    // MARK: - Auth

    /// The user's credentials are invalid (wrong password, expired token, etc.).
    case authInvalidCredentials(underlying: Error)

    /// The requested user account does not exist.
    case authUserNotFound(underlying: Error)

    /// An account with this email already exists.
    case authEmailAlreadyInUse(underlying: Error)

    /// The password does not meet strength requirements.
    case authWeakPassword(underlying: Error)

    /// A generic authentication failure that does not map to a specific case.
    case authFailure(underlying: Error)

    // MARK: - Remote Config

    /// Remote Config fetch was throttled by the server.
    case remoteConfigThrottled(underlying: Error)

    /// Remote Config fetch or activation failed.
    case remoteConfigFetchFailed(underlying: Error)

    /// A requested Remote Config value could not be decoded to the expected type.
    case remoteConfigDecodingFailed(key: String, underlying: Error)

    // MARK: - Messaging

    /// APNs token registration failed.
    case messagingTokenRegistrationFailed(underlying: Error)

    /// A generic messaging error.
    case messagingFailure(underlying: Error)

    // MARK: - Firestore

    /// The requested document was not found.
    case firestoreDocumentNotFound(path: String)

    /// A Firestore read or write operation failed.
    case firestoreOperationFailed(underlying: Error)

    /// Decoding a Firestore document to the expected model failed.
    case firestoreDecodingFailed(path: String, underlying: Error)

    /// Encoding a model for Firestore write failed.
    case firestoreEncodingFailed(path: String, underlying: Error)

    // MARK: - General

    /// A module that was not enabled in configuration was accessed.
    case moduleNotEnabled(module: String)

    /// FirebaseKit has not been configured yet. Call ``FirebaseKit/configure(_:)`` first.
    case notConfigured

    /// An error that does not fit any other category.
    case unknown(underlying: Error)
}

// MARK: - LocalizedError

extension FirebaseKitError: LocalizedError {

    public var errorDescription: String? {
        switch self {
        case .authInvalidCredentials:
            return "Invalid credentials. Please check your email and password."
        case .authUserNotFound:
            return "No account found for the provided credentials."
        case .authEmailAlreadyInUse:
            return "An account with this email already exists."
        case .authWeakPassword:
            return "The password is too weak. Please choose a stronger password."
        case .authFailure(let underlying):
            return "Authentication failed: \(underlying.localizedDescription)"
        case .remoteConfigThrottled:
            return "Remote Config requests are being throttled. Try again later."
        case .remoteConfigFetchFailed(let underlying):
            return "Remote Config fetch failed: \(underlying.localizedDescription)"
        case .remoteConfigDecodingFailed(let key, _):
            return "Failed to decode Remote Config value for key '\(key)'."
        case .messagingTokenRegistrationFailed(let underlying):
            return "FCM token registration failed: \(underlying.localizedDescription)"
        case .messagingFailure(let underlying):
            return "Messaging error: \(underlying.localizedDescription)"
        case .firestoreDocumentNotFound(let path):
            return "Document not found at path '\(path)'."
        case .firestoreOperationFailed(let underlying):
            return "Firestore operation failed: \(underlying.localizedDescription)"
        case .firestoreDecodingFailed(let path, _):
            return "Failed to decode Firestore document at '\(path)'."
        case .firestoreEncodingFailed(let path, _):
            return "Failed to encode model for Firestore document at '\(path)'."
        case .moduleNotEnabled(let module):
            return "The '\(module)' module is not enabled. Enable it in FirebaseKitConfiguration."
        case .notConfigured:
            return "FirebaseKit has not been configured. Call FirebaseKit.configure(_:) first."
        case .unknown(let underlying):
            return "An unexpected error occurred: \(underlying.localizedDescription)"
        }
    }
}
