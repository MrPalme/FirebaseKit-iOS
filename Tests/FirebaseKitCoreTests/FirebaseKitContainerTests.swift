//
//  FirebaseKitContainerTests.swift
//  FirebaseKit
//
//  Created by Markus Mock on 22.02.26.
//

import XCTest
@testable import FirebaseKitCore

final class FirebaseKitContainerTests: XCTestCase {

    override func tearDown() {
        FirebaseKitContainer.shared.reset()
        super.tearDown()
    }

    func testContainerStartsEmpty() {
        FirebaseKitContainer.shared.reset()
        XCTAssertNil(FirebaseKitContainer.shared.configuration)
        XCTAssertNil(FirebaseKitContainer.shared.authService)
        XCTAssertNil(FirebaseKitContainer.shared.remoteConfigService)
        XCTAssertNil(FirebaseKitContainer.shared.messagingService)
        XCTAssertNil(FirebaseKitContainer.shared.firestoreService)
        XCTAssertNil(FirebaseKitContainer.shared.storageService)
        XCTAssertNil(FirebaseKitContainer.shared.realtimeDatabaseService)
        XCTAssertNil(FirebaseKitContainer.shared.analyticsService)
    }

    func testSetConfiguration() {
        let config = FirebaseKitConfiguration(environment: .staging)
        FirebaseKitContainer.shared.setConfiguration(config)
        XCTAssertNotNil(FirebaseKitContainer.shared.configuration)
        XCTAssertEqual(FirebaseKitContainer.shared.configuration?.environment, .staging)
    }

    func testResetClearsEverything() {
        let config = FirebaseKitConfiguration()
        FirebaseKitContainer.shared.setConfiguration(config)
        XCTAssertNotNil(FirebaseKitContainer.shared.configuration)

        FirebaseKitContainer.shared.reset()
        XCTAssertNil(FirebaseKitContainer.shared.configuration)
    }

    func testLoggerFallsBackToConsoleLogger() {
        FirebaseKitContainer.shared.reset()
        // Should not crash — returns default console logger
        let logger = FirebaseKitContainer.shared.logger
        XCTAssertTrue(logger is FirebaseKitConsoleLogger)
    }

    func testStringProviderFallsBackToDefaults() {
        FirebaseKitContainer.shared.reset()
        let provider = FirebaseKitContainer.shared.stringProvider
        XCTAssertTrue(provider is FirebaseKitDefaultStrings)
    }
}
