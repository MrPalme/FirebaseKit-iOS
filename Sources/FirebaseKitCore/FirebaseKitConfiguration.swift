//
//  FirebaseKitConfiguration.swift
//  FirebaseKit
//
//  Created by Markus Mock on 22.02.26.
//

import Foundation

/// Configuration object passed to ``FirebaseKit/configure(_:)`` during
/// app launch.
///
/// The host app is responsible for calling `FirebaseApp.configure()` (or
/// providing a `configureClosure`) **before** calling
/// ``FirebaseKit/configure(_:)``. FirebaseKit does not read
/// `GoogleService-Info.plist` on its own — that responsibility stays with
/// the host app.
///
/// ```swift
/// // In your App init or AppDelegate:
/// FirebaseApp.configure()
///
/// try FirebaseKit.configure(
///     FirebaseKitConfiguration(
///         environment: .debug,
///         modules: .all
///     )
/// )
/// ```
public struct FirebaseKitConfiguration: Sendable {

    /// Which modules the host app wants to enable.
    public struct Modules: OptionSet, Sendable {
        public let rawValue: Int
        public init(rawValue: Int) { self.rawValue = rawValue }

        public static let auth = Modules(rawValue: 1 << 0)
        public static let remoteConfig = Modules(rawValue: 1 << 1)
        public static let messaging = Modules(rawValue: 1 << 2)
        public static let firestore = Modules(rawValue: 1 << 3)
        public static let storage = Modules(rawValue: 1 << 4)
        public static let realtimeDatabase = Modules(rawValue: 1 << 5)
        public static let analytics = Modules(rawValue: 1 << 6)

        /// All currently implemented modules.
        public static let all: Modules = [
            .auth, .remoteConfig, .messaging, .firestore,
            .storage, .realtimeDatabase, .analytics,
        ]
    }

    /// The runtime environment (debug / staging / production).
    public let environment: FirebaseKitEnvironment

    /// Which modules should be initialized.
    public let modules: Modules

    /// Localized string provider. Defaults to ``FirebaseKitDefaultStrings``.
    public let stringProvider: FirebaseKitStringProviding

    /// Logger implementation. Defaults to ``FirebaseKitConsoleLogger``.
    public let logger: FirebaseKitLogging

    /// Creates a new configuration.
    ///
    /// - Parameters:
    ///   - environment: The runtime environment. Defaults to `.production`.
    ///   - modules: Which modules to enable. Defaults to `.all`.
    ///   - stringProvider: Override strings. Defaults to ``FirebaseKitDefaultStrings()``.
    ///   - logger: Override logger. Defaults to ``FirebaseKitConsoleLogger()``.
    public init(
        environment: FirebaseKitEnvironment = .production,
        modules: Modules = .all,
        stringProvider: FirebaseKitStringProviding = FirebaseKitDefaultStrings(),
        logger: FirebaseKitLogging = FirebaseKitConsoleLogger()
    ) {
        self.environment = environment
        self.modules = modules
        self.stringProvider = stringProvider
        self.logger = logger
    }
}
