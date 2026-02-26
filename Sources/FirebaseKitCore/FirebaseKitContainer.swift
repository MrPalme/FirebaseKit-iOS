//
//  FirebaseKitContainer.swift
//  FirebaseKit
//
//  Created by Markus Mock on 22.02.26.
//

import Foundation

/// A lightweight dependency container that holds references to the services
/// registered by each FirebaseKit module.
///
/// The container is populated during ``FirebaseKit/configure(_:)`` and
/// provides module services through the ``FirebaseKit`` facade. Host apps
/// do not interact with the container directly.
public final class FirebaseKitContainer: @unchecked Sendable {

    // MARK: - Singleton

    /// The shared container instance.
    public static let shared = FirebaseKitContainer()

    private let lock = NSLock()

    // MARK: - Configuration

    /// The active configuration. `nil` until ``FirebaseKit/configure(_:)`` is called.
    public private(set) var configuration: FirebaseKitConfiguration?

    /// The active logger. Falls back to a console logger when unconfigured.
    public var logger: FirebaseKitLogging {
        lock.lock()
        defer { lock.unlock() }
        return configuration?.logger ?? FirebaseKitConsoleLogger(minimumLevel: .info)
    }

    /// The active string provider. Falls back to default English strings when unconfigured.
    public var stringProvider: FirebaseKitStringProviding {
        lock.lock()
        defer { lock.unlock() }
        return configuration?.stringProvider ?? FirebaseKitDefaultStrings()
    }

    // MARK: - Service Storage

    private var _authService: (any FirebaseKitAuthServing)?
    private var _remoteConfigService: (any FirebaseKitRemoteConfigServing)?
    private var _messagingService: (any FirebaseKitMessagingServing)?
    private var _firestoreService: (any FirebaseKitFirestoreServing)?
    private var _storageService: (any FirebaseKitStorageServing)?
    private var _realtimeDatabaseService: (any FirebaseKitRealtimeDatabaseServing)?
    private var _analyticsService: (any FirebaseKitAnalyticsServing)?

    // MARK: - Service Access

    /// The registered auth service.
    public var authService: (any FirebaseKitAuthServing)? {
        lock.lock()
        defer { lock.unlock() }
        return _authService
    }

    /// The registered remote config service.
    public var remoteConfigService: (any FirebaseKitRemoteConfigServing)? {
        lock.lock()
        defer { lock.unlock() }
        return _remoteConfigService
    }

    /// The registered messaging service.
    public var messagingService: (any FirebaseKitMessagingServing)? {
        lock.lock()
        defer { lock.unlock() }
        return _messagingService
    }

    /// The registered firestore service.
    public var firestoreService: (any FirebaseKitFirestoreServing)? {
        lock.lock()
        defer { lock.unlock() }
        return _firestoreService
    }

    /// The registered storage service.
    public var storageService: (any FirebaseKitStorageServing)? {
        lock.lock()
        defer { lock.unlock() }
        return _storageService
    }

    /// The registered realtime database service.
    public var realtimeDatabaseService: (any FirebaseKitRealtimeDatabaseServing)? {
        lock.lock()
        defer { lock.unlock() }
        return _realtimeDatabaseService
    }

    /// The registered analytics service.
    public var analyticsService: (any FirebaseKitAnalyticsServing)? {
        lock.lock()
        defer { lock.unlock() }
        return _analyticsService
    }

    // MARK: - Registration

    /// Stores the active configuration.
    public func setConfiguration(_ config: FirebaseKitConfiguration) {
        lock.lock()
        defer { lock.unlock() }
        configuration = config
    }

    /// Registers the auth service implementation.
    public func registerAuth(_ service: any FirebaseKitAuthServing) {
        lock.lock()
        defer { lock.unlock() }
        _authService = service
    }

    /// Registers the remote config service implementation.
    public func registerRemoteConfig(_ service: any FirebaseKitRemoteConfigServing) {
        lock.lock()
        defer { lock.unlock() }
        _remoteConfigService = service
    }

    /// Registers the messaging service implementation.
    public func registerMessaging(_ service: any FirebaseKitMessagingServing) {
        lock.lock()
        defer { lock.unlock() }
        _messagingService = service
    }

    /// Registers the firestore service implementation.
    public func registerFirestore(_ service: any FirebaseKitFirestoreServing) {
        lock.lock()
        defer { lock.unlock() }
        _firestoreService = service
    }

    /// Registers the storage service implementation.
    public func registerStorage(_ service: any FirebaseKitStorageServing) {
        lock.lock()
        defer { lock.unlock() }
        _storageService = service
    }

    /// Registers the realtime database service implementation.
    public func registerRealtimeDatabase(_ service: any FirebaseKitRealtimeDatabaseServing) {
        lock.lock()
        defer { lock.unlock() }
        _realtimeDatabaseService = service
    }

    /// Registers the analytics service implementation.
    public func registerAnalytics(_ service: any FirebaseKitAnalyticsServing) {
        lock.lock()
        defer { lock.unlock() }
        _analyticsService = service
    }

    /// Resets the container. Primarily useful for testing.
    public func reset() {
        lock.lock()
        defer { lock.unlock() }
        configuration = nil
        _authService = nil
        _remoteConfigService = nil
        _messagingService = nil
        _firestoreService = nil
        _storageService = nil
        _realtimeDatabaseService = nil
        _analyticsService = nil
    }

    // MARK: - Init

    private init() {}
}
