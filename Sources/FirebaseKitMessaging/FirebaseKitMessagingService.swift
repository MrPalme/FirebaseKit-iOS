//
//  FirebaseKitMessagingService.swift
//  FirebaseKit
//
//  Created by Markus Mock on 22.02.26.
//

import Foundation
import FirebaseMessaging
import FirebaseKitCore
#if canImport(UIKit)
import UIKit
#endif

/// Concrete implementation of ``FirebaseKitMessagingServing`` backed by
/// Firebase Cloud Messaging.
///
/// Register this service after calling ``FirebaseKit/configure(_:)``:
///
/// ```swift
/// try FirebaseKit.configure(config)
/// FirebaseKitMessagingService.register()
/// ```
///
/// ## Required AppDelegate Hooks
///
/// Your `AppDelegate` (or SwiftUI lifecycle equivalent) must forward
/// the following callbacks:
///
/// ```swift
/// func application(
///     _ application: UIApplication,
///     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
/// ) {
///     FirebaseKit.messaging.setAPNSToken(deviceToken)
/// }
///
/// func application(
///     _ application: UIApplication,
///     didReceiveRemoteNotification userInfo: [AnyHashable: Any],
///     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
/// ) {
///     let result = FirebaseKit.messaging.handleRemoteNotification(userInfo)
///     completionHandler(result == .handled ? .newData : .noData)
/// }
/// ```
public final class FirebaseKitMessagingService: NSObject, @unchecked Sendable, FirebaseKitMessagingServing {

    // MARK: - Properties

    private let messaging: Messaging
    private let lock = NSLock()
    private var _currentFCMToken: String?
    private var tokenContinuation: AsyncStream<String?>.Continuation?

    public let fcmTokenStream: AsyncStream<String?>

    public var currentFCMToken: String? {
        lock.lock()
        defer { lock.unlock() }
        return _currentFCMToken
    }

    // MARK: - Init

    /// Creates the messaging service.
    ///
    /// - Parameter messaging: The `Messaging` instance. Defaults to `Messaging.messaging()`.
    public init(messaging: Messaging = Messaging.messaging()) {
        self.messaging = messaging

        var continuation: AsyncStream<String?>.Continuation!
        self.fcmTokenStream = AsyncStream { continuation = $0 }
        self.tokenContinuation = continuation

        super.init()

        // Set ourselves as the messaging delegate
        messaging.delegate = self

        // Seed the current token if available
        _currentFCMToken = messaging.fcmToken
    }

    deinit {
        tokenContinuation?.finish()
    }

    // MARK: - Registration

    /// Registers this service into the ``FirebaseKitContainer``.
    ///
    /// Call this once after ``FirebaseKit/configure(_:)``.
    public static func register(messaging: Messaging = Messaging.messaging()) {
        let container = FirebaseKitContainer.shared
        guard let config = container.configuration else {
            fkError("Cannot register MessagingService: FirebaseKit is not configured.")
            return
        }
        guard config.modules.contains(.messaging) else {
            fkInfo("Messaging module is disabled — skipping registration.")
            return
        }

        let service = FirebaseKitMessagingService(messaging: messaging)
        container.registerMessaging(service)
        fkInfo("MessagingService registered.")
    }

    // MARK: - FirebaseKitMessagingServing

    public func registerForRemoteNotifications() {
        #if canImport(UIKit)
        DispatchQueue.main.async {
            UIApplication.shared.registerForRemoteNotifications()
        }
        fkInfo("Registered for remote notifications.")
        #else
        fkWarning("registerForRemoteNotifications() is only available on iOS.")
        #endif
    }

    public func setAPNSToken(_ token: Data) {
        messaging.apnsToken = token
        let tokenHex = token.map { String(format: "%02x", $0) }.joined()
        fkDebug("APNs token set: \(tokenHex.prefix(16))…")
    }

    public func handleRemoteNotification(
        _ userInfo: [AnyHashable: Any]
    ) -> FirebaseKitNotificationHandlingResult {
        // Check if this is a Firebase message
        guard userInfo["gcm.message_id"] != nil || userInfo["google.c.a.e"] != nil else {
            fkDebug("Notification is not a Firebase message — not handled.")
            return .notHandled
        }

        Messaging.messaging().appDidReceiveMessage(userInfo)
        fkDebug("Firebase notification handled.")
        return .handled
    }

    public func subscribe(toTopic topic: String) async throws {
        do {
            try await messaging.subscribe(toTopic: topic)
            fkInfo("Subscribed to FCM topic: \(topic)")
        } catch {
            throw FirebaseKitError.messagingFailure(underlying: error)
        }
    }

    public func unsubscribe(fromTopic topic: String) async throws {
        do {
            try await messaging.unsubscribe(fromTopic: topic)
            fkInfo("Unsubscribed from FCM topic: \(topic)")
        } catch {
            throw FirebaseKitError.messagingFailure(underlying: error)
        }
    }
}

// MARK: - MessagingDelegate

extension FirebaseKitMessagingService: MessagingDelegate {

    public func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        lock.lock()
        _currentFCMToken = fcmToken
        lock.unlock()

        tokenContinuation?.yield(fcmToken)
        fkInfo("FCM token updated: \(fcmToken?.prefix(16) ?? "nil")…")
    }
}
