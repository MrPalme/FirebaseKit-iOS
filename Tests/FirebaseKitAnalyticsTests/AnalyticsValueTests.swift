//
//  AnalyticsValueTests.swift
//  FirebaseKit
//
//  Created by Markus Mock on 22.02.26.
//

import XCTest
@testable import FirebaseKitCore

final class AnalyticsValueTests: XCTestCase {

    // MARK: - AnalyticsValue → NSObject Conversion

    func testStringValueConversion() {
        let value = AnalyticsValue.string("hello")
        let ns = value.nsValue
        XCTAssertTrue(ns is NSString)
        XCTAssertEqual(ns as? String, "hello")
    }

    func testIntValueConversion() {
        let value = AnalyticsValue.int(42)
        let ns = value.nsValue
        XCTAssertTrue(ns is NSNumber)
        XCTAssertEqual((ns as? NSNumber)?.intValue, 42)
    }

    func testDoubleValueConversion() {
        let value = AnalyticsValue.double(3.14)
        let ns = value.nsValue
        XCTAssertTrue(ns is NSNumber)
        XCTAssertEqual((ns as! NSNumber).doubleValue, 3.14, accuracy: 0.001)
    }

    func testBoolValueConversion() {
        let trueValue = AnalyticsValue.bool(true)
        let falseValue = AnalyticsValue.bool(false)

        XCTAssertEqual((trueValue.nsValue as? NSNumber)?.boolValue, true)
        XCTAssertEqual((falseValue.nsValue as? NSNumber)?.boolValue, false)
    }

    // MARK: - AnalyticsEvent Conformance

    func testCustomEventConformance() {
        let event = TestEvent.buttonTapped(name: "upgrade")
        XCTAssertEqual(event.name, "button_tapped")
        XCTAssertEqual(event.parameters.count, 1)

        if case .string(let value) = event.parameters["button_name"] {
            XCTAssertEqual(value, "upgrade")
        } else {
            XCTFail("Expected string parameter")
        }
    }

    // MARK: - AnalyticsScreen Conformance

    func testCustomScreenConformance() {
        let screen = TestScreen.home
        XCTAssertEqual(screen.screenName, "home")
        XCTAssertNil(screen.screenClass) // defaults
    }

    func testCustomScreenWithClass() {
        let screen = TestScreenWithClass.detail
        XCTAssertEqual(screen.screenName, "detail")
        XCTAssertEqual(screen.screenClass, "DetailViewController")
    }

    // MARK: - Parameter Dictionary Building

    func testParameterDictionaryConversion() {
        let params: [String: AnalyticsValue] = [
            "item": .string("widget"),
            "count": .int(3),
            "price": .double(9.99),
            "discounted": .bool(true),
        ]

        let nsDict = params.mapValues { $0.nsValue }
        XCTAssertEqual(nsDict.count, 4)
        XCTAssertEqual(nsDict["item"] as? String, "widget")
        XCTAssertEqual((nsDict["count"] as? NSNumber)?.intValue, 3)
        XCTAssertEqual((nsDict["price"] as! NSNumber).doubleValue, 9.99, accuracy: 0.001)
        XCTAssertEqual((nsDict["discounted"] as? NSNumber)?.boolValue, true)
    }
}

// MARK: - Test Helpers

private enum TestEvent: AnalyticsEvent {
    case buttonTapped(name: String)

    var name: String {
        switch self {
        case .buttonTapped: return "button_tapped"
        }
    }

    var parameters: [String: AnalyticsValue] {
        switch self {
        case .buttonTapped(let name):
            return ["button_name": .string(name)]
        }
    }
}

private enum TestScreen: String, AnalyticsScreen {
    case home
    case settings

    var screenName: String { rawValue }
}

private enum TestScreenWithClass: AnalyticsScreen {
    case detail

    var screenName: String { "detail" }
    var screenClass: String? { "DetailViewController" }
}
