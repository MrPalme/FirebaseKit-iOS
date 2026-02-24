//
//  FirebaseKitAuthService.swift
//  FirebaseKit
//
//  Created by Markus Mock on 22.02.26.
//

import Foundation
import FirebaseAuth
import FirebaseKitCore

/// Concrete implementation of ``FirebaseKitAuthServing`` backed by
/// Firebase Authentication.
///
/// Register this service after calling ``FirebaseKit/configure(_:)``:
///
/// ```swift
/// try FirebaseKit.configure(config)
/// FirebaseKitAuthService.register()
/// ```
public final class FirebaseKitAuthService: @unchecked Sendable, FirebaseKitAuthServing {

    // MARK: - Properties

    private let auth: Auth
    private let lock = NSLock()
    private var _session: FirebaseAuthSession = .signedOut
    private var sessionContinuation: AsyncStream<FirebaseAuthSession>.Continuation?
    private var stateListenerHandle: AuthStateDidChangeListenerHandle?

    // MARK: - FirebaseKitAuthServing

    public var session: FirebaseAuthSession {
        lock.lock()
        defer { lock.unlock() }
        return _session
    }

    public let sessionStream: AsyncStream<FirebaseAuthSession>

    // MARK: - Init

    /// Creates the auth service.
    ///
    /// - Parameter auth: The `Auth` instance to wrap. Defaults to `Auth.auth()`.
    public init(auth: Auth = Auth.auth()) {
        self.auth = auth

        var continuation: AsyncStream<FirebaseAuthSession>.Continuation!
        self.sessionStream = AsyncStream { continuation = $0 }
        self.sessionContinuation = continuation

        // Seed initial state
        if let currentUser = auth.currentUser {
            _session = FirebaseAuthSession(
                state: .signedIn,
                user: currentUser.toFirebaseKitUser()
            )
        }

        // Listen for auth state changes
        stateListenerHandle = auth.addStateDidChangeListener { [weak self] _, user in
            self?.handleStateChange(user: user)
        }
    }

    deinit {
        if let handle = stateListenerHandle {
            auth.removeStateDidChangeListener(handle)
        }
        sessionContinuation?.finish()
    }

    // MARK: - Registration

    /// Registers this service into the ``FirebaseKitContainer``.
    ///
    /// Call this once after ``FirebaseKit/configure(_:)``.
    public static func register(auth: Auth = Auth.auth()) {
        let container = FirebaseKitContainer.shared
        guard let config = container.configuration else {
            fkError("Cannot register AuthService: FirebaseKit is not configured.")
            return
        }
        guard config.modules.contains(.auth) else {
            fkInfo("Auth module is disabled — skipping registration.")
            return
        }

        let service = FirebaseKitAuthService(auth: auth)
        container.registerAuth(service)
        fkInfo("AuthService registered.")
    }

    // MARK: - Sign In / Out

    @discardableResult
    public func signIn(email: String, password: String) async throws -> FirebaseAuthUser {
        do {
            let result = try await auth.signIn(withEmail: email, password: password)
            let user = result.user.toFirebaseKitUser()
            fkInfo("User signed in: \(user.uid)")
            return user
        } catch {
            throw AuthErrorMapper.map(error)
        }
    }

    @discardableResult
    public func createUser(email: String, password: String) async throws -> FirebaseAuthUser {
        do {
            let result = try await auth.createUser(withEmail: email, password: password)
            let user = result.user.toFirebaseKitUser()
            fkInfo("User created: \(user.uid)")
            return user
        } catch {
            throw AuthErrorMapper.map(error)
        }
    }

    public func signOut() throws {
        do {
            try auth.signOut()
            fkInfo("User signed out.")
        } catch {
            throw FirebaseKitError.authFailure(underlying: error)
        }
    }

    @discardableResult
    public func signInWithApple(identityToken: Data, nonce: String) async throws -> FirebaseAuthUser {
        guard let tokenString = String(data: identityToken, encoding: .utf8) else {
            throw FirebaseKitError.authInvalidCredentials(
                underlying: NSError(
                    domain: "FirebaseKit",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Invalid Apple identity token data."]
                )
            )
        }

        let credential = OAuthProvider.credential(
            providerID: .apple,
            idToken: tokenString,
            rawNonce: nonce
        )

        do {
            let result = try await auth.signIn(with: credential)
            let user = result.user.toFirebaseKitUser()
            fkInfo("User signed in with Apple: \(user.uid)")
            return user
        } catch {
            throw AuthErrorMapper.map(error)
        }
    }

    @discardableResult
    public func signInWithGoogle(idToken: String, accessToken: String) async throws -> FirebaseAuthUser {
        let credential = GoogleAuthProvider.credential(
            withIDToken: idToken,
            accessToken: accessToken
        )

        do {
            let result = try await auth.signIn(with: credential)
            let user = result.user.toFirebaseKitUser()
            fkInfo("User signed in with Google: \(user.uid)")
            return user
        } catch {
            throw AuthErrorMapper.map(error)
        }
    }

    public func sendPasswordReset(to email: String) async throws {
        do {
            try await auth.sendPasswordReset(withEmail: email)
            fkInfo("Password reset email sent to: \(email)")
        } catch {
            throw AuthErrorMapper.map(error)
        }
    }

    // MARK: - Private

    private func handleStateChange(user: User?) {
        let newSession: FirebaseAuthSession
        if let user {
            newSession = FirebaseAuthSession(state: .signedIn, user: user.toFirebaseKitUser())
        } else {
            newSession = .signedOut
        }

        lock.lock()
        _session = newSession
        lock.unlock()

        sessionContinuation?.yield(newSession)
    }
}

// MARK: - User Mapping

private extension User {
    func toFirebaseKitUser() -> FirebaseAuthUser {
        FirebaseAuthUser(
            uid: uid,
            email: email,
            displayName: displayName
        )
    }
}
