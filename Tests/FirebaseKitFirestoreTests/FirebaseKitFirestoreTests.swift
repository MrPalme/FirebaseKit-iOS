//
//  FirebaseKitFirestoreTests.swift
//  FirebaseKit
//
//  Created by Markus Mock on 22.02.26.
//

import XCTest
@testable import FirebaseKitCore

final class FirebaseKitFirestoreTests: XCTestCase {

    // MARK: - Snapshot Model Tests

    func testFirebaseKitDocumentSnapshotExists() {
        let snapshot = FirebaseKitDocumentSnapshot(
            documentID: "abc123",
            data: ["name": "Alice", "age": 30],
            exists: true
        )
        XCTAssertEqual(snapshot.documentID, "abc123")
        XCTAssertTrue(snapshot.exists)
        XCTAssertNotNil(snapshot.data)
        XCTAssertEqual(snapshot.data?["name"] as? String, "Alice")
    }

    func testFirebaseKitDocumentSnapshotNotExists() {
        let snapshot = FirebaseKitDocumentSnapshot(
            documentID: "missing",
            data: nil,
            exists: false
        )
        XCTAssertEqual(snapshot.documentID, "missing")
        XCTAssertFalse(snapshot.exists)
        XCTAssertNil(snapshot.data)
    }

    // MARK: - Decode Closure Tests

    func testDecodeClosureSuccess() {
        let snapshot = FirebaseKitDocumentSnapshot(
            documentID: "user1",
            data: ["name": "Bob", "email": "bob@example.com"],
            exists: true
        )

        struct User: Equatable {
            let id: String
            let name: String
            let email: String
        }

        let decode: (FirebaseKitDocumentSnapshot) throws -> User = { snap in
            guard let data = snap.data,
                  let name = data["name"] as? String,
                  let email = data["email"] as? String else {
                throw NSError(domain: "test", code: 0, userInfo: [NSLocalizedDescriptionKey: "Missing fields"])
            }
            return User(id: snap.documentID, name: name, email: email)
        }

        let user = try? decode(snapshot)
        XCTAssertNotNil(user)
        XCTAssertEqual(user?.id, "user1")
        XCTAssertEqual(user?.name, "Bob")
        XCTAssertEqual(user?.email, "bob@example.com")
    }

    func testDecodeClosureFailure() {
        let snapshot = FirebaseKitDocumentSnapshot(
            documentID: "bad",
            data: ["foo": "bar"],
            exists: true
        )

        let decode: (FirebaseKitDocumentSnapshot) throws -> String = { snap in
            guard let name = snap.data?["name"] as? String else {
                throw NSError(domain: "test", code: 0, userInfo: [NSLocalizedDescriptionKey: "Missing 'name'"])
            }
            return name
        }

        XCTAssertThrowsError(try decode(snapshot))
    }

    // MARK: - Integration Tests (require Firebase emulator)

    // These tests require a running Firestore emulator.
    // They are included as scaffolding for CI/CD integration.
    //
    // func testGetDocument() async throws { }
    // func testSetDocument() async throws { }
    // func testDeleteDocument() async throws { }
    // func testQuery() async throws { }
}
