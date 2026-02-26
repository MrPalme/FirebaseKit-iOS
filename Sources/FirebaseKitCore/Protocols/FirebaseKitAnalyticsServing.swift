//
//  FirebaseKitAnalyticsServing.swift
//  FirebaseKit
//
//  Created by Markus Mock on 22.02.26.
//

import Foundation

// MARK: - Analytics Value (Strongly Typed)

/// A type-safe representation of an analytics parameter value.
///
/// Use this instead of `Any` to ensure only valid types reach Firebase Analytics.
///
/// ```swift
/// let params: [String: AnalyticsValue] = [
///     "item_name": .string("Premium Plan"),
///     "price": .double(9.99),
///     "quantity": .int(1),
///     "is_trial": .bool(true),
/// ]
/// ```
public enum AnalyticsValue: Sendable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)

    /// Converts this value to an `NSObject` suitable for Firebase Analytics.
    public var nsValue: NSObject {
        switch self {
        case .string(let v): return v as NSString
        case .int(let v): return v as NSNumber
        case .double(let v): return v as NSNumber
        case .bool(let v): return v as NSNumber
        }
    }
}

// MARK: - Analytics Event Protocol

/// A protocol for host-app-defined analytics events.
///
/// The host app defines events as an enum conforming to this protocol.
/// FirebaseKit logs them without knowing the specific event vocabulary.
///
/// ```swift
/// enum AppEvent: AnalyticsEvent {
///     case buttonTapped(name: String, screen: String)
///     case purchaseCompleted(productId: String, price: Double)
///
///     var name: String {
///         switch self {
///         case .buttonTapped: return "button_tapped"
///         case .purchaseCompleted: return "purchase_completed"
///         }
///     }
///
///     var parameters: [String: AnalyticsValue] {
///         switch self {
///         case .buttonTapped(let name, let screen):
///             return ["button_name": .string(name), "screen": .string(screen)]
///         case .purchaseCompleted(let productId, let price):
///             return ["product_id": .string(productId), "price": .double(price)]
///         }
///     }
/// }
/// ```
public protocol AnalyticsEvent: Sendable {
    /// The event name (e.g. `"button_tapped"`). Must be a valid Firebase event name.
    var name: String { get }

    /// Key-value parameters attached to the event.
    var parameters: [String: AnalyticsValue] { get }
}

// MARK: - Analytics Screen Protocol

/// A protocol for host-app-defined screen identifiers.
///
/// The host app defines screens as an enum conforming to this protocol.
/// FirebaseKit maps them to the standard `screen_view` event.
///
/// ```swift
/// enum AppScreen: String, AnalyticsScreen {
///     case home, settings, profile, onboarding
///
///     var screenName: String { rawValue }
///     var screenClass: String? { nil } // defaults to "SwiftUI"
/// }
/// ```
public protocol AnalyticsScreen: Sendable {
    /// The screen name logged as `screen_name`.
    var screenName: String { get }

    /// The screen class logged as `screen_class`. Defaults to `"SwiftUI"`.
    var screenClass: String? { get }
}

/// Default implementation: `screenClass` returns `nil` (the service will use `"SwiftUI"`).
public extension AnalyticsScreen {
    var screenClass: String? { nil }
}

// MARK: - Protocol

/// Contract for the FirebaseKit Analytics service.
///
/// The concrete implementation lives in `FirebaseKitAnalytics`.
public protocol FirebaseKitAnalyticsServing: Sendable {

    /// Logs a custom event.
    ///
    /// - Parameter event: An ``AnalyticsEvent`` defined by the host app.
    func log(event: some AnalyticsEvent)

    /// Logs a screen view event.
    ///
    /// Maps to the standard `screen_view` event with `screen_name` and
    /// `screen_class` parameters.
    ///
    /// - Parameter screen: An ``AnalyticsScreen`` defined by the host app.
    func screen(_ screen: some AnalyticsScreen)

    /// Sets a user property.
    ///
    /// - Parameters:
    ///   - name: The property name (must be a valid Firebase user property name).
    ///   - value: The property value, or `nil` to clear.
    func setUserProperty(_ name: String, value: String?)

    /// Sets the user ID for analytics. Pass `nil` to clear.
    ///
    /// - Important: **Never pass PII** (emails, phone numbers) as the user ID.
    ///   Use a stable, opaque identifier instead.
    ///
    /// - Parameter userId: An opaque, stable user identifier.
    func setUserId(_ userId: String?)
}
