//
//  FirebaseKitErrorTests.swift
//  FirebaseKit
//
//  Created by Markus Mock on 22.02.26.
//

import XCTest
@testable import FirebaseKitCore

final class FirebaseKitErrorTests: XCTestCase {

    // MARK: - Error Description

    func testAuthInvalidCredentialsDescription() {
        let error = FirebaseKitError.authInvalidCredentials(
            underlying: NSError(domain: "test", code: 0)
        )
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription!.contains("Invalid credentials"))
    }

    func testAuthUserNotFoundDescription() {
        let error = FirebaseKitError.authUserNotFound(
            underlying: NSError(domain: "test", code: 0)
        )
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription!.contains("No account found"))
    }

    func testAuthEmailAlreadyInUseDescription() {
        let error = FirebaseKitError.authEmailAlreadyInUse(
            underlying: NSError(domain: "test", code: 0)
        )
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription!.contains("already exists"))
    }

    func testFirestoreDocumentNotFoundDescription() {
        let error = FirebaseKitError.firestoreDocumentNotFound(path: "users/abc")
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription!.contains("users/abc"))
    }

    func testModuleNotEnabledDescription() {
        let error = FirebaseKitError.moduleNotEnabled(module: "auth")
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription!.contains("auth"))
    }

    func testNotConfiguredDescription() {
        let error = FirebaseKitError.notConfigured
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription!.contains("not been configured"))
    }

    func testRemoteConfigDecodingFailedDescription() {
        let error = FirebaseKitError.remoteConfigDecodingFailed(
            key: "feature_flag",
            underlying: NSError(domain: "test", code: 0)
        )
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription!.contains("feature_flag"))
    }
}
