//
//  FirebaseKitRemoteConfigService.swift
//  FirebaseKit
//
//  Created by Markus Mock on 22.02.26.
//

import Foundation
import FirebaseRemoteConfig
import FirebaseKitCore

/// Concrete implementation of ``FirebaseKitRemoteConfigServing`` backed
/// by Firebase Remote Config.
///
/// Register this service after calling ``FirebaseKit/configure(_:)``:
///
/// ```swift
/// try FirebaseKit.configure(config)
/// FirebaseKitRemoteConfigService.register()
/// ```
public final class FirebaseKitRemoteConfigService: @unchecked Sendable, FirebaseKitRemoteConfigServing {

    // MARK: - Properties

    private let remoteConfig: RemoteConfig
    private var updateContinuation: AsyncStream<Void>.Continuation?
    private var configUpdateRegistration: ConfigUpdateListenerRegistration?

    public let configUpdateStream: AsyncStream<Void>

    // MARK: - Init

    /// Creates the Remote Config service.
    ///
    /// - Parameter remoteConfig: The `RemoteConfig` instance. Defaults to `RemoteConfig.remoteConfig()`.
    public init(remoteConfig: RemoteConfig = RemoteConfig.remoteConfig()) {
        self.remoteConfig = remoteConfig

        var continuation: AsyncStream<Void>.Continuation!
        self.configUpdateStream = AsyncStream { continuation = $0 }
        self.updateContinuation = continuation

        // Listen for real-time config updates
        configUpdateRegistration = remoteConfig.addOnConfigUpdateListener { [weak self] update, error in
            if let error {
                fkWarning("Remote Config update listener error: \(error.localizedDescription)")
                return
            }
            // Auto-activate on update
            remoteConfig.activate { _, activateError in
                if let activateError {
                    fkWarning("Remote Config activation failed: \(activateError.localizedDescription)")
                    return
                }
                self?.updateContinuation?.yield(())
                fkDebug("Remote Config update activated.")
            }
        }
    }

    deinit {
        configUpdateRegistration?.remove()
        updateContinuation?.finish()
    }

    // MARK: - Registration

    /// Registers this service into the ``FirebaseKitContainer``.
    ///
    /// Call this once after ``FirebaseKit/configure(_:)``.
    ///
    /// - Parameters:
    ///   - remoteConfig: The `RemoteConfig` instance. Defaults to `RemoteConfig.remoteConfig()`.
    ///   - defaults: Default values to set on the Remote Config instance. Keys are
    ///     Remote Config key names, values are `NSObject`-compatible defaults.
    public static func register(
        remoteConfig: RemoteConfig = RemoteConfig.remoteConfig(),
        defaults: [String: NSObject]? = nil
    ) {
        let container = FirebaseKitContainer.shared
        guard let config = container.configuration else {
            fkError("Cannot register RemoteConfigService: FirebaseKit is not configured.")
            return
        }
        guard config.modules.contains(.remoteConfig) else {
            fkInfo("RemoteConfig module is disabled — skipping registration.")
            return
        }

        // Apply debug fetch interval for non-production environments
        if config.environment != .production {
            let settings = RemoteConfigSettings()
            settings.minimumFetchInterval = 0
            remoteConfig.configSettings = settings
            fkDebug("RemoteConfig: minimumFetchInterval set to 0 for \(config.environment.rawValue).")
        }

        if let defaults {
            remoteConfig.setDefaults(defaults)
        }

        let service = FirebaseKitRemoteConfigService(remoteConfig: remoteConfig)
        container.registerRemoteConfig(service)
        fkInfo("RemoteConfigService registered.")
    }

    // MARK: - FirebaseKitRemoteConfigServing

    @discardableResult
    public func fetchAndActivate() async throws -> Bool {
        do {
            let status = try await remoteConfig.fetchAndActivate()
            let didActivate = status == .successFetchedFromRemote
            fkInfo("RemoteConfig fetchAndActivate: \(status == .successFetchedFromRemote ? "fetched new values" : "using cached values")")
            return didActivate
        } catch {
            throw RemoteConfigErrorMapper.map(error)
        }
    }

    public func value<T>(for key: RemoteConfigKey<T>) throws -> T {
        let configValue = remoteConfig.configValue(forKey: key.name)

        // If the value has never been set (source is .static), return default
        if configValue.source == .static {
            return key.defaultValue
        }

        return try RemoteConfigValueDecoder.decode(configValue, for: key)
    }
}
