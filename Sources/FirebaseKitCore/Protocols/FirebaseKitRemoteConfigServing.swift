//
//  FirebaseKitRemoteConfigServing.swift
//  FirebaseKit
//
//  Created by Markus Mock on 22.02.26.
//

import Foundation

/// A typed key for Remote Config values.
///
/// The generic parameter `T` declares the expected Swift type for the value
/// behind this key. Supported types: `Bool`, `Int`, `Double`, `String`,
/// `URL`, and any `Decodable` type (decoded from JSON).
///
/// ```swift
/// extension RemoteConfigKey where T == Bool {
///     static let featureEnabled = RemoteConfigKey<Bool>("feature_enabled", default: false)
/// }
/// ```
public struct RemoteConfigKey<T>: Sendable {
    /// The raw key name as stored in Firebase Remote Config.
    public let name: String

    /// The default value returned when the key is absent or decoding fails.
    public let defaultValue: T

    /// Creates a typed Remote Config key.
    ///
    /// - Parameters:
    ///   - name: The key name in Firebase Remote Config.
    ///   - default: The fallback value.
    public init(_ name: String, default defaultValue: T) {
        self.name = name
        self.defaultValue = defaultValue
    }
}

/// Contract for the FirebaseKit Remote Config service.
///
/// The concrete implementation lives in `FirebaseKitRemoteConfig`.
public protocol FirebaseKitRemoteConfigServing: Sendable {

    /// Fetches and activates the latest Remote Config values.
    ///
    /// - Returns: `true` if new values were fetched and activated,
    ///   `false` if the cached values were already up to date.
    /// - Throws: ``FirebaseKitError`` on failure.
    @discardableResult
    func fetchAndActivate() async throws -> Bool

    /// Reads a typed value from the active Remote Config.
    ///
    /// - Parameter key: A ``RemoteConfigKey`` declaring the expected type.
    /// - Returns: The decoded value, or the key's default if absent or un-decodable.
    /// - Throws: ``FirebaseKitError`` if decoding fails fatally.
    func value<T>(for key: RemoteConfigKey<T>) throws -> T

    /// An asynchronous stream that emits whenever Remote Config values
    /// are updated (after a successful fetch-and-activate cycle).
    var configUpdateStream: AsyncStream<Void> { get }
}
