//
//  FirebaseKitFirestoreServing.swift
//  FirebaseKit
//
//  Created by Markus Mock on 22.02.26.
//

import Foundation

/// A type-erased representation of a Firestore document snapshot.
///
/// This allows the protocol contract in `FirebaseKitCore` to remain
/// independent of the Firebase SDK while still providing enough
/// data for host-app decode closures.
public struct FirebaseKitDocumentSnapshot: Sendable {
    /// The document ID.
    public let documentID: String
    /// The raw data dictionary, if the document exists.
    public let data: [String: Any]?
    /// Whether the document exists in Firestore.
    public let exists: Bool

    public init(documentID: String, data: [String: Any]?, exists: Bool) {
        self.documentID = documentID
        self.data = data
        self.exists = exists
    }
}

/// Contract for the FirebaseKit Firestore service.
///
/// Model mapping is fully delegated to the host app through `decode` and
/// `encode` closures. FirebaseKit never assumes a particular schema.
///
/// The concrete implementation lives in `FirebaseKitFirestore`.
public protocol FirebaseKitFirestoreServing: Sendable {

    /// Fetches a single document and decodes it using the provided closure.
    ///
    /// - Parameters:
    ///   - path: The full document path (e.g., `"users/abc123"`).
    ///   - type: The target model type (for generic inference).
    ///   - decode: A closure that converts the snapshot into the model.
    /// - Returns: The decoded model.
    /// - Throws: ``FirebaseKitError`` on failure.
    func getDocument<T: Sendable>(
        path: String,
        as type: T.Type,
        decode: @Sendable (FirebaseKitDocumentSnapshot) throws -> T
    ) async throws -> T

    /// Writes a document using the provided encode closure.
    ///
    /// - Parameters:
    ///   - path: The full document path.
    ///   - value: The model to write.
    ///   - merge: Whether to merge fields or overwrite the entire document. Defaults to `false`.
    ///   - encode: A closure that converts the model into a Firestore-compatible dictionary.
    /// - Throws: ``FirebaseKitError`` on failure.
    func setDocument<T: Sendable>(
        path: String,
        value: T,
        merge: Bool,
        encode: @Sendable (T) throws -> [String: Any]
    ) async throws

    /// Deletes a document at the given path.
    ///
    /// - Parameter path: The full document path.
    /// - Throws: ``FirebaseKitError`` on failure.
    func deleteDocument(path: String) async throws

    /// Queries a collection and decodes each document using the provided closure.
    ///
    /// - Parameters:
    ///   - collectionPath: The collection path (e.g., `"users"`).
    ///   - build: A closure that modifies the base query (add filters, ordering, limits).
    ///            The closure receives an opaque ``FirebaseKitQuery`` value.
    ///   - decode: A closure that converts each document snapshot into the model.
    /// - Returns: An array of decoded models.
    /// - Throws: ``FirebaseKitError`` on failure.
    func query<T: Sendable>(
        collectionPath: String,
        build: @Sendable (FirebaseKitQuery) -> FirebaseKitQuery,
        decode: @Sendable (FirebaseKitDocumentSnapshot) throws -> T
    ) async throws -> [T]
}

/// Default parameter values for ``FirebaseKitFirestoreServing``.
public extension FirebaseKitFirestoreServing {

    /// Convenience overload with `merge` defaulting to `false`.
    func setDocument<T: Sendable>(
        path: String,
        value: T,
        encode: @Sendable (T) throws -> [String: Any]
    ) async throws {
        try await setDocument(path: path, value: value, merge: false, encode: encode)
    }

    /// Convenience overload with an identity query builder (no filters).
    func query<T: Sendable>(
        collectionPath: String,
        decode: @Sendable (FirebaseKitDocumentSnapshot) throws -> T
    ) async throws -> [T] {
        try await query(collectionPath: collectionPath, build: { $0 }, decode: decode)
    }
}

/// An opaque query builder that wraps Firestore's `Query`.
///
/// This type is defined in Core so the protocol can reference it, but
/// the concrete builder methods are added by the `FirebaseKitFirestore` module.
public final class FirebaseKitQuery: @unchecked Sendable {

    /// Internal storage for the underlying Firestore query. Typed as `Any`
    /// in Core; the Firestore module casts it to `FirebaseFirestore.Query`.
    public let _wrapped: Any

    public init(_ wrapped: Any) {
        _wrapped = wrapped
    }
}
