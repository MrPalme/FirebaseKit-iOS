//
//  LogHelper.swift
//  FirebaseKit
//
//  Created by Markus Mock on 22.02.26.
//

import Foundation

/// Internal helpers for logging within FirebaseKit modules.
///
/// Modules call these free functions instead of accessing the logger directly,
/// which keeps call-sites concise and ensures log messages include the correct
/// source location automatically.
public func fkLog(
    _ level: FirebaseKitLogLevel,
    _ message: @autoclosure () -> String,
    file: String = #file,
    function: String = #function,
    line: UInt = #line
) {
    FirebaseKitContainer.shared.logger.log(level, message(), file: file, function: function, line: line)
}

/// Convenience for debug-level logs.
public func fkDebug(
    _ message: @autoclosure () -> String,
    file: String = #file,
    function: String = #function,
    line: UInt = #line
) {
    fkLog(.debug, message(), file: file, function: function, line: line)
}

/// Convenience for info-level logs.
public func fkInfo(
    _ message: @autoclosure () -> String,
    file: String = #file,
    function: String = #function,
    line: UInt = #line
) {
    fkLog(.info, message(), file: file, function: function, line: line)
}

/// Convenience for warning-level logs.
public func fkWarning(
    _ message: @autoclosure () -> String,
    file: String = #file,
    function: String = #function,
    line: UInt = #line
) {
    fkLog(.warning, message(), file: file, function: function, line: line)
}

/// Convenience for error-level logs.
public func fkError(
    _ message: @autoclosure () -> String,
    file: String = #file,
    function: String = #function,
    line: UInt = #line
) {
    fkLog(.error, message(), file: file, function: function, line: line)
}
