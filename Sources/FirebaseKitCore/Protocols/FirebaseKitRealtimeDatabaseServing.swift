//
//  FirebaseKitRealtimeDatabaseServing.swift
//  FirebaseKit
//
//  Created by Markus Mock on 22.02.26.
//

import Foundation

// MARK: - Typed Database Path

/// A typed reference to a location in Firebase Realtime Database.
///
/// The generic parameter `T` declares the expected Swift type at this path.
/// Host apps define stable paths as static properties, giving compile-time
/// type safety for reads, writes, and observations.
///
/// ```swift
/// extension RealtimeDBPath where T == UserProfile {
///     static func profile(uid: String) -> RealtimeDBPath<UserProfile> {
///         RealtimeDBPath("users/\(uid)/profile")
///     }
/// }
///
/// extension RealtimeDBPath where T == [String: Bool] {
///     static func onlineUsers() -> RealtimeDBPath<[String: Bool]> {
///         RealtimeDBPath("presence/online")
///     }
/// }
/// ```
public struct RealtimeDBPath<T: Decodable & Sendable>: Sendable {
    /// The database reference path (e.g. `"users/abc/profile"`).
    public let path: String

    /// Creates a typed Realtime Database path.
    ///
    /// - Parameter path: The database reference path.
    public init(_ path: String) {
        self.path = path
    }
}

// MARK: - Protocol

/// Contract for the FirebaseKit Realtime Database service.
///
/// The concrete implementation lives in `FirebaseKitRealtimeDatabase`.
public protocol FirebaseKitRealtimeDatabaseServing: Sendable {

    /// Writes a value to the given path, overwriting any existing data.
    ///
    /// - Parameters:
    ///   - path: The database path.
    ///   - value: A JSON-compatible value (`String`, `Int`, `Double`, `Bool`,
    ///     `[String: Any]`, `[Any]`, or `nil`).
    /// - Throws: ``FirebaseKitError`` on failure.
    func set(path: String, value: Any) async throws

    /// Updates specific children at the given path without overwriting siblings.
    ///
    /// - Parameters:
    ///   - path: The database path.
    ///   - values: A dictionary of child keys → values to merge.
    /// - Throws: ``FirebaseKitError`` on failure.
    func update(path: String, values: [String: Any]) async throws

    /// Reads a value from the given typed path.
    ///
    /// - Parameter path: A ``RealtimeDBPath`` declaring the expected `Decodable` type.
    /// - Returns: The decoded value, or `nil` if nothing exists at the path.
    /// - Throws: ``FirebaseKitError`` on failure.
    func get<T: Decodable & Sendable>(path: RealtimeDBPath<T>) async throws -> T?

    /// Reads a value from a raw path.
    ///
    /// - Parameters:
    ///   - path: The database path.
    ///   - type: The expected `Decodable` type.
    /// - Returns: The decoded value, or `nil` if nothing exists at the path.
    /// - Throws: ``FirebaseKitError`` on failure.
    func get<T: Decodable & Sendable>(path: String, type: T.Type) async throws -> T?

    /// Observes continuous value changes at the given typed path.
    ///
    /// - Parameter path: A ``RealtimeDBPath`` declaring the expected `Decodable` type.
    /// - Returns: An ``AsyncStream`` that yields the decoded value every time
    ///   data changes at the path (including the initial read).
    func observe<T: Decodable & Sendable>(path: RealtimeDBPath<T>) -> AsyncStream<T?>

    /// Observes continuous value changes at a raw path.
    ///
    /// - Parameters:
    ///   - path: The database path.
    ///   - type: The expected `Decodable` type.
    /// - Returns: An ``AsyncStream`` of decoded values.
    func observe<T: Decodable & Sendable>(path: String, type: T.Type) -> AsyncStream<T?>

    /// Removes data at the given path.
    ///
    /// - Parameter path: The database path.
    /// - Throws: ``FirebaseKitError`` on failure.
    func remove(path: String) async throws
}
