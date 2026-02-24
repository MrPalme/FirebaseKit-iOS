//
//  FirebaseKitAuthServing.swift
//  FirebaseKit
//
//  Created by Markus Mock on 22.02.26.
//

import Foundation

/// The current authentication state.
public enum FirebaseAuthState: String, Sendable {
    /// No user is signed in.
    case signedOut
    /// A user is signed in.
    case signedIn
}

/// A lightweight representation of the currently signed-in Firebase user.
///
/// This struct is intentionally minimal. Host apps that need richer user
/// models should map from ``FirebaseAuthUser`` in their own domain layer.
public struct FirebaseAuthUser: Sendable, Equatable {
    /// The Firebase UID.
    public let uid: String
    /// The user's email, if available.
    public let email: String?
    /// The user's display name, if available.
    public let displayName: String?

    public init(uid: String, email: String?, displayName: String?) {
        self.uid = uid
        self.email = email
        self.displayName = displayName
    }
}

/// A snapshot of the current authentication session.
public struct FirebaseAuthSession: Sendable, Equatable {
    /// The authentication state.
    public let state: FirebaseAuthState
    /// The current user, if signed in.
    public let user: FirebaseAuthUser?

    public init(state: FirebaseAuthState, user: FirebaseAuthUser?) {
        self.state = state
        self.user = user
    }

    /// A convenience value representing a signed-out session.
    public static let signedOut = FirebaseAuthSession(state: .signedOut, user: nil)
}

/// Contract for the FirebaseKit authentication service.
///
/// The concrete implementation lives in `FirebaseKitAuth` and wraps
/// `FirebaseAuth`. Host apps can also provide their own mock
/// implementation for previews and tests.
public protocol FirebaseKitAuthServing: Sendable {

    /// The current session snapshot.
    var session: FirebaseAuthSession { get }

    /// An asynchronous stream of session updates, emitted whenever
    /// the auth state changes (sign-in, sign-out, token refresh).
    var sessionStream: AsyncStream<FirebaseAuthSession> { get }

    /// Signs in with email and password.
    ///
    /// - Parameters:
    ///   - email: The user's email address.
    ///   - password: The user's password.
    /// - Returns: The signed-in user.
    /// - Throws: ``FirebaseKitError`` on failure.
    @discardableResult
    func signIn(email: String, password: String) async throws -> FirebaseAuthUser

    /// Creates a new account with email and password.
    ///
    /// - Parameters:
    ///   - email: The desired email address.
    ///   - password: The desired password.
    /// - Returns: The newly created user.
    /// - Throws: ``FirebaseKitError`` on failure.
    @discardableResult
    func createUser(email: String, password: String) async throws -> FirebaseAuthUser

    /// Signs out the current user.
    ///
    /// - Throws: ``FirebaseKitError`` on failure.
    func signOut() throws

    /// Signs in with Apple credentials.
    ///
    /// - Note: The host app is responsible for presenting the Apple Sign-In
    ///   UI and obtaining the `identityToken` and `nonce`. Pass them here
    ///   for FirebaseKit to complete the Firebase sign-in flow.
    ///
    /// - Parameters:
    ///   - identityToken: The raw identity token from `ASAuthorization`.
    ///   - nonce: The raw nonce used when initiating the Apple Sign-In request.
    /// - Returns: The signed-in user.
    /// - Throws: ``FirebaseKitError`` on failure.
    @discardableResult
    func signInWithApple(identityToken: Data, nonce: String) async throws -> FirebaseAuthUser

    /// Signs in with Google credentials.
    ///
    /// - Note: The host app is responsible for presenting the Google Sign-In
    ///   UI and obtaining the `idToken` and `accessToken`. Pass them here
    ///   for FirebaseKit to complete the Firebase sign-in flow.
    ///
    /// - Parameters:
    ///   - idToken: The Google ID token.
    ///   - accessToken: The Google access token.
    /// - Returns: The signed-in user.
    /// - Throws: ``FirebaseKitError`` on failure.
    @discardableResult
    func signInWithGoogle(idToken: String, accessToken: String) async throws -> FirebaseAuthUser

    /// Sends a password reset email to the given address.
    ///
    /// - Parameter email: The email address to send the reset link to.
    /// - Throws: ``FirebaseKitError`` on failure.
    func sendPasswordReset(to email: String) async throws
}
