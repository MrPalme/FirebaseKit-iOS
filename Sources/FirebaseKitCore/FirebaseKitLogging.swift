//
//  FirebaseKitLogging.swift
//  FirebaseKit
//
//  Created by Markus Mock on 22.02.26.
//

import Foundation
import os.log

/// Log severity levels used throughout FirebaseKit.
public enum FirebaseKitLogLevel: Int, Sendable, Comparable {
    case debug = 0
    case info = 1
    case warning = 2
    case error = 3

    public static func < (lhs: FirebaseKitLogLevel, rhs: FirebaseKitLogLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

/// A protocol for injecting custom logging into FirebaseKit.
///
/// FirebaseKit ships a ``FirebaseKitConsoleLogger`` that writes to `os_log`.
/// Host apps can conform their own logger to this protocol and inject it
/// via ``FirebaseKitConfiguration/logger``.
public protocol FirebaseKitLogging: Sendable {

    /// The minimum level at which messages are emitted. Messages below this
    /// level are silently discarded.
    var minimumLevel: FirebaseKitLogLevel { get }

    /// Log a message at the given level.
    ///
    /// - Parameters:
    ///   - level: Severity of the message.
    ///   - message: The log message (auto-closure for lazy evaluation).
    ///   - file: Source file (populated automatically).
    ///   - function: Function name (populated automatically).
    ///   - line: Line number (populated automatically).
    func log(
        _ level: FirebaseKitLogLevel,
        _ message: @autoclosure () -> String,
        file: String,
        function: String,
        line: UInt
    )
}

// MARK: - Default Implementation

/// A console logger that writes to Apple's Unified Logging system (`os_log`).
///
/// This is the default logger used when no custom logger is provided
/// in ``FirebaseKitConfiguration``.
public struct FirebaseKitConsoleLogger: FirebaseKitLogging {

    public let minimumLevel: FirebaseKitLogLevel

    /// Creates a console logger.
    ///
    /// - Parameter minimumLevel: The minimum severity to emit. Defaults to `.info`.
    public init(minimumLevel: FirebaseKitLogLevel = .info) {
        self.minimumLevel = minimumLevel
    }

    private static let osLog = OSLog(subsystem: "com.firebasekit", category: "FirebaseKit")

    public func log(
        _ level: FirebaseKitLogLevel,
        _ message: @autoclosure () -> String,
        file: String,
        function: String,
        line: UInt
    ) {
        guard level >= minimumLevel else { return }
        let text = message()
        let fileName = (file as NSString).lastPathComponent
        let prefix = "[\(label(for: level))] \(fileName):\(line) \(function)"
        os_log("%{public}@ — %{public}@", log: Self.osLog, type: osLogType(for: level), prefix, text)
    }

    // MARK: - Helpers

    private func label(for level: FirebaseKitLogLevel) -> String {
        switch level {
        case .debug: return "DEBUG"
        case .info: return "INFO"
        case .warning: return "WARN"
        case .error: return "ERROR"
        }
    }

    private func osLogType(for level: FirebaseKitLogLevel) -> OSLogType {
        switch level {
        case .debug: return .debug
        case .info: return .info
        case .warning: return .default
        case .error: return .error
        }
    }
}
