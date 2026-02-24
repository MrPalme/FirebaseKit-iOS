//
//  FirebaseKitDefaultStringsTests.swift
//  FirebaseKit
//
//  Created by Markus Mock on 22.02.26.
//

import XCTest
@testable import FirebaseKitCore

final class FirebaseKitDefaultStringsTests: XCTestCase {

    private let strings = FirebaseKitDefaultStrings()

    func testAllKeysReturnNonEmptyStrings() {
        for key in FirebaseKitStringKey.allCases {
            let value = strings.string(key)
            XCTAssertFalse(value.isEmpty, "String for key '\(key.rawValue)' should not be empty.")
        }
    }

    func testSpecificKeys() {
        XCTAssertTrue(strings.string(.authInvalidCredentials).contains("Invalid"))
        XCTAssertTrue(strings.string(.firestoreDocumentNotFound).contains("not found"))
        XCTAssertTrue(strings.string(.unknownError).contains("unexpected"))
    }
}
