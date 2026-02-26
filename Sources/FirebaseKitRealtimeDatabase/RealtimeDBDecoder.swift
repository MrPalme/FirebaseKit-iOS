//
//  RealtimeDBDecoder.swift
//  FirebaseKit
//
//  Created by Markus Mock on 22.02.26.
//

import Foundation
import FirebaseDatabase
import FirebaseKitCore

/// Decodes Realtime Database snapshots into `Decodable` types.
///
/// Supports primitive types (`String`, `Int`, `Double`, `Bool`) directly,
/// and complex types via `JSONSerialization` → `JSONDecoder`.
enum RealtimeDBDecoder {

    /// Decodes a ``DataSnapshot`` into the given `Decodable` type.
    ///
    /// - Parameters:
    ///   - snapshot: The database snapshot.
    ///   - type: The target type.
    /// - Returns: The decoded value.
    /// - Throws: An error if decoding fails.
    static func decode<T: Decodable>(snapshot: DataSnapshot, type: T.Type) throws -> T {
        guard let value = snapshot.value else {
            throw DecodingError.valueNotFound(
                T.self,
                DecodingError.Context(
                    codingPath: [],
                    debugDescription: "Snapshot value is nil."
                )
            )
        }

        // Direct primitive support
        if let result = value as? T {
            return result
        }

        // Handle NSNumber → Bool / Int / Double
        if let number = value as? NSNumber {
            if T.self == Bool.self, let result = number.boolValue as? T {
                return result
            }
            if T.self == Int.self, let result = number.intValue as? T {
                return result
            }
            if T.self == Double.self, let result = number.doubleValue as? T {
                return result
            }
        }

        // Fall back to JSON round-trip for complex Decodable types
        let jsonData = try JSONSerialization.data(withJSONObject: value, options: [])
        return try JSONDecoder().decode(T.self, from: jsonData)
    }
}
