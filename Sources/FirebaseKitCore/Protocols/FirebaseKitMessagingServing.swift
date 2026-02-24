//
//  FirebaseKitMessagingServing.swift
//  FirebaseKit
//
//  Created by Markus Mock on 22.02.26.
//

import Foundation

/// The result of handling a remote notification payload.
public enum FirebaseKitNotificationHandlingResult: Sendable {
    /// The notification was handled successfully by FirebaseKit.
    case handled
    /// The notification is not a Firebase-originated message and should
    /// be handled by the host app or another handler.
    case notHandled
}

/// Contract for the FirebaseKit Messaging (FCM) service.
///
/// The concrete implementation lives in `FirebaseKitMessaging`.
///
/// ## Required AppDelegate Hooks
///
/// The host app **must** forward the following UIApplicationDelegate callbacks
/// to FirebaseKit for messaging to work correctly:
///
/// 1. `application(_:didRegisterForRemoteNotificationsWithDeviceToken:)` —
///    Call ``setAPNSToken(_:)`` with the raw device token.
///
/// 2. `application(_:didReceiveRemoteNotification:fetchCompletionHandler:)` —
///    Call ``handleRemoteNotification(_:)`` and inspect the result.
///
/// 3. `application(_:didFailToRegisterForRemoteNotificationsWithError:)` —
///    Log or handle the error as appropriate.
///
/// Additionally, call ``registerForRemoteNotifications()`` once the user has
/// granted notification permission (typically after `UNUserNotificationCenter`
/// authorization).
public protocol FirebaseKitMessagingServing: Sendable {

    /// An asynchronous stream of FCM token updates.
    ///
    /// Emits `nil` when the token is invalidated, and a new `String` when
    /// a fresh token is obtained.
    var fcmTokenStream: AsyncStream<String?> { get }

    /// The current FCM token, if available.
    var currentFCMToken: String? { get }

    /// Triggers registration for remote notifications via UIApplication.
    ///
    /// Call this after the user grants notification permissions.
    func registerForRemoteNotifications()

    /// Forwards the APNs device token from
    /// `application(_:didRegisterForRemoteNotificationsWithDeviceToken:)`.
    ///
    /// - Parameter token: The raw APNs device token.
    func setAPNSToken(_ token: Data)

    /// Handles an incoming remote notification.
    ///
    /// - Parameter userInfo: The notification payload from
    ///   `application(_:didReceiveRemoteNotification:fetchCompletionHandler:)`.
    /// - Returns: Whether the notification was handled by FirebaseKit.
    func handleRemoteNotification(_ userInfo: [AnyHashable: Any]) -> FirebaseKitNotificationHandlingResult

    /// Subscribes to an FCM topic.
    ///
    /// - Parameter topic: The topic name to subscribe to.
    /// - Throws: ``FirebaseKitError`` on failure.
    func subscribe(toTopic topic: String) async throws

    /// Unsubscribes from an FCM topic.
    ///
    /// - Parameter topic: The topic name to unsubscribe from.
    /// - Throws: ``FirebaseKitError`` on failure.
    func unsubscribe(fromTopic topic: String) async throws
}
