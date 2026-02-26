//
//  FirebaseKit.swift
//  FirebaseKit
//
//  Created by Markus Mock on 22.02.26.
//

import Foundation

/// The main entry point for FirebaseKit.
///
/// Call ``configure(_:)`` once during app launch (after `FirebaseApp.configure()`),
/// then access module services through the static properties.
///
/// ```swift
/// // Configure
/// try FirebaseKit.configure(
///     FirebaseKitConfiguration(environment: .debug, modules: .all)
/// )
///
/// // Use services
/// let user = try await FirebaseKit.auth.signIn(email: "…", password: "…")
/// ```
public enum FirebaseKit {

    /// Whether FirebaseKit has been configured.
    public static var isConfigured: Bool {
        FirebaseKitContainer.shared.configuration != nil
    }

    /// Configures FirebaseKit with the given configuration.
    ///
    /// This must be called **once** during app startup, after
    /// `FirebaseApp.configure()` has been invoked by the host app.
    /// Calling it a second time will reset the container.
    ///
    /// - Parameter configuration: The configuration describing which modules
    ///   to enable and what overrides to apply.
    /// - Throws: ``FirebaseKitError/notConfigured`` if a critical
    ///   precondition is not met.
    public static func configure(_ configuration: FirebaseKitConfiguration) throws {
        let container = FirebaseKitContainer.shared
        container.reset()
        container.setConfiguration(configuration)

        fkInfo("FirebaseKit configured — environment: \(configuration.environment.rawValue), modules: \(configuration.modules)")
    }

    // MARK: - Module Access

    /// The authentication service.
    ///
    /// - Important: The `auth` module must be enabled in ``FirebaseKitConfiguration/modules``
    ///   and ``FirebaseKitAuth`` must be linked in your target.
    public static var auth: any FirebaseKitAuthServing {
        guard let service = FirebaseKitContainer.shared.authService else {
            fatalError(
                "[FirebaseKit] Auth service is not available. "
                + "Ensure the 'auth' module is enabled in FirebaseKitConfiguration "
                + "and FirebaseKitAuth is linked in your target. "
                + "Call FirebaseKitAuthService.register() after FirebaseKit.configure()."
            )
        }
        return service
    }

    /// The Remote Config service.
    ///
    /// - Important: The `remoteConfig` module must be enabled in ``FirebaseKitConfiguration/modules``
    ///   and ``FirebaseKitRemoteConfig`` must be linked in your target.
    public static var remoteConfig: any FirebaseKitRemoteConfigServing {
        guard let service = FirebaseKitContainer.shared.remoteConfigService else {
            fatalError(
                "[FirebaseKit] RemoteConfig service is not available. "
                + "Ensure the 'remoteConfig' module is enabled in FirebaseKitConfiguration "
                + "and FirebaseKitRemoteConfig is linked in your target. "
                + "Call FirebaseKitRemoteConfigService.register() after FirebaseKit.configure()."
            )
        }
        return service
    }

    /// The Messaging (FCM) service.
    ///
    /// - Important: The `messaging` module must be enabled in ``FirebaseKitConfiguration/modules``
    ///   and ``FirebaseKitMessaging`` must be linked in your target.
    public static var messaging: any FirebaseKitMessagingServing {
        guard let service = FirebaseKitContainer.shared.messagingService else {
            fatalError(
                "[FirebaseKit] Messaging service is not available. "
                + "Ensure the 'messaging' module is enabled in FirebaseKitConfiguration "
                + "and FirebaseKitMessaging is linked in your target. "
                + "Call FirebaseKitMessagingService.register() after FirebaseKit.configure()."
            )
        }
        return service
    }

    /// The Firestore service.
    ///
    /// - Important: The `firestore` module must be enabled in ``FirebaseKitConfiguration/modules``
    ///   and ``FirebaseKitFirestore`` must be linked in your target.
    public static var firestore: any FirebaseKitFirestoreServing {
        guard let service = FirebaseKitContainer.shared.firestoreService else {
            fatalError(
                "[FirebaseKit] Firestore service is not available. "
                + "Ensure the 'firestore' module is enabled in FirebaseKitConfiguration "
                + "and FirebaseKitFirestore is linked in your target. "
                + "Call FirebaseKitFirestoreService.register() after FirebaseKit.configure()."
            )
        }
        return service
    }

    /// The Storage service.
    ///
    /// - Important: The `storage` module must be enabled in ``FirebaseKitConfiguration/modules``
    ///   and ``FirebaseKitStorage`` must be linked in your target.
    public static var storage: any FirebaseKitStorageServing {
        guard let service = FirebaseKitContainer.shared.storageService else {
            fatalError(
                "[FirebaseKit] Storage service is not available. "
                + "Ensure the 'storage' module is enabled in FirebaseKitConfiguration "
                + "and FirebaseKitStorage is linked in your target. "
                + "Call FirebaseKitStorageService.register() after FirebaseKit.configure()."
            )
        }
        return service
    }

    /// The Realtime Database service.
    ///
    /// - Important: The `realtimeDatabase` module must be enabled in ``FirebaseKitConfiguration/modules``
    ///   and ``FirebaseKitRealtimeDatabase`` must be linked in your target.
    public static var realtimeDatabase: any FirebaseKitRealtimeDatabaseServing {
        guard let service = FirebaseKitContainer.shared.realtimeDatabaseService else {
            fatalError(
                "[FirebaseKit] RealtimeDatabase service is not available. "
                + "Ensure the 'realtimeDatabase' module is enabled in FirebaseKitConfiguration "
                + "and FirebaseKitRealtimeDatabase is linked in your target. "
                + "Call FirebaseKitRealtimeDatabaseService.register() after FirebaseKit.configure()."
            )
        }
        return service
    }

    /// The Analytics service.
    ///
    /// - Important: The `analytics` module must be enabled in ``FirebaseKitConfiguration/modules``
    ///   and ``FirebaseKitAnalytics`` must be linked in your target.
    public static var analytics: any FirebaseKitAnalyticsServing {
        guard let service = FirebaseKitContainer.shared.analyticsService else {
            fatalError(
                "[FirebaseKit] Analytics service is not available. "
                + "Ensure the 'analytics' module is enabled in FirebaseKitConfiguration "
                + "and FirebaseKitAnalytics is linked in your target. "
                + "Call FirebaseKitAnalyticsService.register() after FirebaseKit.configure()."
            )
        }
        return service
    }
}
