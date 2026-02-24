//
//  FirebaseKitConfigurationTests.swift
//  FirebaseKit
//
//  Created by Markus Mock on 22.02.26.
//

import XCTest
@testable import FirebaseKitCore

final class FirebaseKitConfigurationTests: XCTestCase {

    func testDefaultConfiguration() {
        let config = FirebaseKitConfiguration()
        XCTAssertEqual(config.environment, .production)
        XCTAssertTrue(config.modules.contains(.auth))
        XCTAssertTrue(config.modules.contains(.remoteConfig))
        XCTAssertTrue(config.modules.contains(.messaging))
        XCTAssertTrue(config.modules.contains(.firestore))
    }

    func testCustomModuleSelection() {
        let config = FirebaseKitConfiguration(modules: [.auth, .remoteConfig])
        XCTAssertTrue(config.modules.contains(.auth))
        XCTAssertTrue(config.modules.contains(.remoteConfig))
        XCTAssertFalse(config.modules.contains(.messaging))
        XCTAssertFalse(config.modules.contains(.firestore))
    }

    func testEnvironmentSetting() {
        let config = FirebaseKitConfiguration(environment: .debug)
        XCTAssertEqual(config.environment, .debug)
    }

    func testCustomStringProvider() {
        struct TestStrings: FirebaseKitStringProviding {
            func string(_ key: FirebaseKitStringKey) -> String { "test" }
        }

        let config = FirebaseKitConfiguration(stringProvider: TestStrings())
        XCTAssertEqual(config.stringProvider.string(.unknownError), "test")
    }
}
