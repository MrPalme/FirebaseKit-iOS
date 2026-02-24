//
//  FirebaseKitFirestoreService.swift
//  FirebaseKit
//
//  Created by Markus Mock on 22.02.26.
//

import Foundation
@preconcurrency import FirebaseFirestore
import FirebaseKitCore

/// Concrete implementation of ``FirebaseKitFirestoreServing`` backed by
/// Cloud Firestore.
///
/// Model mapping is fully delegated to the host app through `encode`/`decode`
/// closures. FirebaseKit never assumes a particular data schema.
///
/// Register this service after calling ``FirebaseKit/configure(_:)``:
///
/// ```swift
/// try FirebaseKit.configure(config)
/// FirebaseKitFirestoreService.register()
/// ```
public final class FirebaseKitFirestoreService: Sendable, FirebaseKitFirestoreServing {

    // MARK: - Properties

    private let db: Firestore

    // MARK: - Init

    /// Creates the Firestore service.
    ///
    /// - Parameter firestore: The `Firestore` instance. Defaults to `Firestore.firestore()`.
    public init(firestore: Firestore = Firestore.firestore()) {
        self.db = firestore
    }

    // MARK: - Registration

    /// Registers this service into the ``FirebaseKitContainer``.
    ///
    /// Call this once after ``FirebaseKit/configure(_:)``.
    public static func register(firestore: Firestore = Firestore.firestore()) {
        let container = FirebaseKitContainer.shared
        guard let config = container.configuration else {
            fkError("Cannot register FirestoreService: FirebaseKit is not configured.")
            return
        }
        guard config.modules.contains(.firestore) else {
            fkInfo("Firestore module is disabled — skipping registration.")
            return
        }

        let service = FirebaseKitFirestoreService(firestore: firestore)
        container.registerFirestore(service)
        fkInfo("FirestoreService registered.")
    }

    // MARK: - FirebaseKitFirestoreServing

    public func getDocument<T: Sendable>(
        path: String,
        as type: T.Type,
        decode: @Sendable (FirebaseKitDocumentSnapshot) throws -> T
    ) async throws -> T {
        do {
            let snapshot = try await db.document(path).getDocument()

            guard snapshot.exists else {
                throw FirebaseKitError.firestoreDocumentNotFound(path: path)
            }

            let kitSnapshot = mapSnapshot(snapshot)

            do {
                return try decode(kitSnapshot)
            } catch {
                throw FirebaseKitError.firestoreDecodingFailed(path: path, underlying: error)
            }
        } catch let error as FirebaseKitError {
            throw error
        } catch {
            throw FirebaseKitError.firestoreOperationFailed(underlying: error)
        }
    }

    public func setDocument<T: Sendable>(
        path: String,
        value: T,
        merge: Bool,
        encode: @Sendable (T) throws -> [String: Any]
    ) async throws {
        let data: [String: Any]
        do {
            data = try encode(value)
        } catch {
            throw FirebaseKitError.firestoreEncodingFailed(path: path, underlying: error)
        }

        do {
            if merge {
                try await db.document(path).setData(data, merge: true)
            } else {
                try await db.document(path).setData(data)
            }
            fkDebug("Document written at path: \(path)")
        } catch {
            throw FirebaseKitError.firestoreOperationFailed(underlying: error)
        }
    }

    public func deleteDocument(path: String) async throws {
        do {
            try await db.document(path).delete()
            fkDebug("Document deleted at path: \(path)")
        } catch {
            throw FirebaseKitError.firestoreOperationFailed(underlying: error)
        }
    }

    public func query<T: Sendable>(
        collectionPath: String,
        build: @Sendable (FirebaseKitQuery) -> FirebaseKitQuery,
        decode: @Sendable (FirebaseKitDocumentSnapshot) throws -> T
    ) async throws -> [T] {
        let baseQuery: Query = db.collection(collectionPath)
        let wrappedQuery = FirebaseKitQuery(baseQuery)
        let finalQuery = build(wrappedQuery)

        guard let firestoreQuery = finalQuery._wrapped as? Query else {
            fatalError("[FirebaseKit] FirebaseKitQuery._wrapped is not a Firestore Query.")
        }

        do {
            let snapshot = try await firestoreQuery.getDocuments()
            return try snapshot.documents.map { doc in
                let kitSnapshot = mapQueryDocumentSnapshot(doc)
                do {
                    return try decode(kitSnapshot)
                } catch {
                    throw FirebaseKitError.firestoreDecodingFailed(
                        path: "\(collectionPath)/\(doc.documentID)",
                        underlying: error
                    )
                }
            }
        } catch let error as FirebaseKitError {
            throw error
        } catch {
            throw FirebaseKitError.firestoreOperationFailed(underlying: error)
        }
    }
}

// MARK: - Snapshot Mapping

private func mapSnapshot(_ snapshot: DocumentSnapshot) -> FirebaseKitDocumentSnapshot {
    FirebaseKitDocumentSnapshot(
        documentID: snapshot.documentID,
        data: snapshot.data(),
        exists: snapshot.exists
    )
}

private func mapQueryDocumentSnapshot(_ snapshot: QueryDocumentSnapshot) -> FirebaseKitDocumentSnapshot {
    FirebaseKitDocumentSnapshot(
        documentID: snapshot.documentID,
        data: snapshot.data(),
        exists: true
    )
}
