//
//  FirebaseKitAnalyticsService.swift
//  FirebaseKit
//
//  Created by Markus Mock on 22.02.26.
//

import Foundation
import FirebaseAnalytics
import FirebaseKitCore

/// Concrete implementation of ``FirebaseKitAnalyticsServing`` backed by
/// Firebase Analytics.
///
/// Register this service after calling ``FirebaseKit/configure(_:)``:
///
/// ```swift
/// try FirebaseKit.configure(config)
/// FirebaseKitAnalyticsService.register()
/// ```
public final class FirebaseKitAnalyticsService: Sendable, FirebaseKitAnalyticsServing {

    // MARK: - Init

    public init() {}

    // MARK: - Registration

    /// Registers this service into the ``FirebaseKitContainer``.
    ///
    /// Call this once after ``FirebaseKit/configure(_:)``.
    public static func register() {
        let container = FirebaseKitContainer.shared
        guard let config = container.configuration else {
            fkError("Cannot register AnalyticsService: FirebaseKit is not configured.")
            return
        }
        guard config.modules.contains(.analytics) else {
            fkInfo("Analytics module is disabled — skipping registration.")
            return
        }

        let service = FirebaseKitAnalyticsService()
        container.registerAnalytics(service)
        fkInfo("AnalyticsService registered.")
    }

    // MARK: - FirebaseKitAnalyticsServing

    public func log(event: some AnalyticsEvent) {
        let params = event.parameters.mapValues { $0.nsValue }
        Analytics.logEvent(event.name, parameters: params)
        fkDebug("Analytics event: '\(event.name)' params: \(event.parameters.keys.joined(separator: ", "))")
    }

    public func screen(_ screen: some AnalyticsScreen) {
        let params: [String: Any] = [
            AnalyticsParameterScreenName: screen.screenName,
            AnalyticsParameterScreenClass: screen.screenClass ?? "SwiftUI",
        ]
        Analytics.logEvent(AnalyticsEventScreenView, parameters: params)
        fkDebug("Analytics screen: '\(screen.screenName)'")
    }

    public func setUserProperty(_ name: String, value: String?) {
        Analytics.setUserProperty(value, forName: name)
        fkDebug("Analytics user property: '\(name)' = '\(value ?? "nil")'")
    }

    public func setUserId(_ userId: String?) {
        Analytics.setUserID(userId)
        fkDebug("Analytics userId: '\(userId ?? "nil")'")
    }
}
