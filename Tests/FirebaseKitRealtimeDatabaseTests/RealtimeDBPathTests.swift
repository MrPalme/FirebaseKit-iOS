//
//  RealtimeDBPathTests.swift
//  FirebaseKit
//
//  Created by Markus Mock on 22.02.26.
//

import XCTest
@testable import FirebaseKitCore

final class RealtimeDBPathTests: XCTestCase {

    func testRealtimeDBPathStoresPath() {
        let path = RealtimeDBPath<String>("users/abc/name")
        XCTAssertEqual(path.path, "users/abc/name")
    }

    func testRealtimeDBPathGenericTypePreserved() {
        // Verify that paths with different types compile and work correctly
        let stringPath = RealtimeDBPath<String>("name")
        let intPath = RealtimeDBPath<Int>("count")
        let boolPath = RealtimeDBPath<Bool>("active")

        XCTAssertEqual(stringPath.path, "name")
        XCTAssertEqual(intPath.path, "count")
        XCTAssertEqual(boolPath.path, "active")
    }

    func testRealtimeDBPathWithDecodableModel() {
        struct UserProfile: Decodable {
            let name: String
            let age: Int
        }

        let path = RealtimeDBPath<UserProfile>("users/abc/profile")
        XCTAssertEqual(path.path, "users/abc/profile")
    }
}
