//
//  RemoteConfigKeyTests.swift
//  FirebaseKit
//
//  Created by Markus Mock on 22.02.26.
//

import XCTest
@testable import FirebaseKitCore

final class RemoteConfigKeyTests: XCTestCase {

    func testBoolKeyCreation() {
        let key = RemoteConfigKey<Bool>("feature_enabled", default: false)
        XCTAssertEqual(key.name, "feature_enabled")
        XCTAssertEqual(key.defaultValue, false)
    }

    func testIntKeyCreation() {
        let key = RemoteConfigKey<Int>("max_retries", default: 3)
        XCTAssertEqual(key.name, "max_retries")
        XCTAssertEqual(key.defaultValue, 3)
    }

    func testDoubleKeyCreation() {
        let key = RemoteConfigKey<Double>("threshold", default: 0.75)
        XCTAssertEqual(key.name, "threshold")
        XCTAssertEqual(key.defaultValue, 0.75, accuracy: 0.001)
    }

    func testStringKeyCreation() {
        let key = RemoteConfigKey<String>("welcome_message", default: "Hello!")
        XCTAssertEqual(key.name, "welcome_message")
        XCTAssertEqual(key.defaultValue, "Hello!")
    }

    func testURLKeyCreation() {
        let url = URL(string: "https://example.com")!
        let key = RemoteConfigKey<URL>("api_endpoint", default: url)
        XCTAssertEqual(key.name, "api_endpoint")
        XCTAssertEqual(key.defaultValue, url)
    }

    func testDecodableKeyCreation() {
        struct Config: Decodable, Equatable {
            let enabled: Bool
            let count: Int
        }

        let defaultConfig = Config(enabled: false, count: 0)
        let key = RemoteConfigKey<Config>("app_config", default: defaultConfig)
        XCTAssertEqual(key.name, "app_config")
        XCTAssertEqual(key.defaultValue, defaultConfig)
    }
}
