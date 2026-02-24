//
//  FirebaseKitQuery+Firestore.swift
//  FirebaseKit
//
//  Created by Markus Mock on 22.02.26.
//

import Foundation
import FirebaseFirestore
import FirebaseKitCore

/// Chainable query-builder extensions on ``FirebaseKitQuery``.
///
/// These methods mirror Firestore's `Query` API and allow host apps
/// to build queries without importing `FirebaseFirestore` directly.
///
/// ```swift
/// let users = try await FirebaseKit.firestore.query(
///     collectionPath: "users",
///     build: { $0.whereField("age", isGreaterThan: 18).order(by: "name").limit(to: 20) },
///     decode: { snapshot in ... }
/// )
/// ```
public extension FirebaseKitQuery {

    // MARK: - Filtering

    /// Adds a filter where the field equals the given value.
    func whereField(_ field: String, isEqualTo value: Any) -> FirebaseKitQuery {
        FirebaseKitQuery(firestoreQuery.whereField(field, isEqualTo: value))
    }

    /// Adds a filter where the field does not equal the given value.
    func whereField(_ field: String, isNotEqualTo value: Any) -> FirebaseKitQuery {
        FirebaseKitQuery(firestoreQuery.whereField(field, isNotEqualTo: value))
    }

    /// Adds a filter where the field is less than the given value.
    func whereField(_ field: String, isLessThan value: Any) -> FirebaseKitQuery {
        FirebaseKitQuery(firestoreQuery.whereField(field, isLessThan: value))
    }

    /// Adds a filter where the field is less than or equal to the given value.
    func whereField(_ field: String, isLessThanOrEqualTo value: Any) -> FirebaseKitQuery {
        FirebaseKitQuery(firestoreQuery.whereField(field, isLessThanOrEqualTo: value))
    }

    /// Adds a filter where the field is greater than the given value.
    func whereField(_ field: String, isGreaterThan value: Any) -> FirebaseKitQuery {
        FirebaseKitQuery(firestoreQuery.whereField(field, isGreaterThan: value))
    }

    /// Adds a filter where the field is greater than or equal to the given value.
    func whereField(_ field: String, isGreaterThanOrEqualTo value: Any) -> FirebaseKitQuery {
        FirebaseKitQuery(firestoreQuery.whereField(field, isGreaterThanOrEqualTo: value))
    }

    /// Adds a filter where the array field contains the given value.
    func whereField(_ field: String, arrayContains value: Any) -> FirebaseKitQuery {
        FirebaseKitQuery(firestoreQuery.whereField(field, arrayContains: value))
    }

    /// Adds a filter where the field value is in the given array.
    func whereField(_ field: String, in values: [Any]) -> FirebaseKitQuery {
        FirebaseKitQuery(firestoreQuery.whereField(field, in: values))
    }

    // MARK: - Ordering

    /// Adds an ascending or descending ordering clause.
    func order(by field: String, descending: Bool = false) -> FirebaseKitQuery {
        FirebaseKitQuery(firestoreQuery.order(by: field, descending: descending))
    }

    // MARK: - Pagination

    /// Limits the number of returned documents.
    func limit(to count: Int) -> FirebaseKitQuery {
        FirebaseKitQuery(firestoreQuery.limit(to: count))
    }

    /// Limits to the last `count` documents.
    func limit(toLast count: Int) -> FirebaseKitQuery {
        FirebaseKitQuery(firestoreQuery.limit(toLast: count))
    }

    // MARK: - Internal Helper

    private var firestoreQuery: Query {
        guard let query = _wrapped as? Query else {
            fatalError("[FirebaseKit] FirebaseKitQuery._wrapped is not a Firestore Query.")
        }
        return query
    }
}
