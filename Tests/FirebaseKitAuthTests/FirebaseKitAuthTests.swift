//
//  FirebaseKitAuthTests.swift
//  FirebaseKit
//
//  Created by Markus Mock on 22.02.26.
//

import XCTest
@testable import FirebaseKitCore
@testable import FirebaseKitAuth

final class FirebaseKitAuthTests: XCTestCase {

    // MARK: - Model Tests

    func testFirebaseAuthUserEquality() {
        let user1 = FirebaseAuthUser(uid: "abc", email: "a@b.com", displayName: "Alice")
        let user2 = FirebaseAuthUser(uid: "abc", email: "a@b.com", displayName: "Alice")
        let user3 = FirebaseAuthUser(uid: "def", email: "d@e.com", displayName: "Bob")

        XCTAssertEqual(user1, user2)
        XCTAssertNotEqual(user1, user3)
    }

    func testFirebaseAuthSessionSignedOut() {
        let session = FirebaseAuthSession.signedOut
        XCTAssertEqual(session.state, .signedOut)
        XCTAssertNil(session.user)
    }

    func testFirebaseAuthSessionSignedIn() {
        let user = FirebaseAuthUser(uid: "abc", email: "a@b.com", displayName: nil)
        let session = FirebaseAuthSession(state: .signedIn, user: user)
        XCTAssertEqual(session.state, .signedIn)
        XCTAssertEqual(session.user?.uid, "abc")
    }

    // MARK: - Integration Tests (require Firebase emulator)

    // These tests require a running Firebase Auth emulator.
    // They are included as scaffolding for CI/CD integration.
    //
    // func testSignInWithEmailAndPassword() async throws { }
    // func testCreateUserWithEmailAndPassword() async throws { }
    // func testSignOut() throws { }
}
