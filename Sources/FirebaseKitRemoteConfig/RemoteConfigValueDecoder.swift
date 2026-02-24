//
//  RemoteConfigValueDecoder.swift
//  FirebaseKit
//
//  Created by Markus Mock on 22.02.26.
//

import Foundation
import FirebaseRemoteConfig
import FirebaseKitCore

/// Decodes `RemoteConfigValue` instances into the expected Swift types
/// declared by ``RemoteConfigKey``.
enum RemoteConfigValueDecoder {

    /// Decodes a remote config value for the given key.
    ///
    /// Supported types: `Bool`, `Int`, `Double`, `String`, `URL`,
    /// and any `Decodable` type (decoded from JSON data).
    ///
    /// - Parameters:
    ///   - configValue: The raw `RemoteConfigValue` from the Firebase SDK.
    ///   - key: The typed key specifying the expected type and default.
    /// - Returns: The decoded value.
    /// - Throws: ``FirebaseKitError/remoteConfigDecodingFailed`` if decoding fails.
    static func decode<T>(_ configValue: RemoteConfigValue, for key: RemoteConfigKey<T>) throws -> T {
        do {
            switch T.self {
            case is Bool.Type:
                return configValue.boolValue as! T

            case is Int.Type:
                return configValue.numberValue.intValue as! T

            case is Double.Type:
                return configValue.numberValue.doubleValue as! T

            case is String.Type:
                let string = configValue.stringValue
                if string.isEmpty { return key.defaultValue }
                return string as! T

            case is URL.Type:
                let string = configValue.stringValue
                guard !string.isEmpty, let url = URL(string: string) else {
                    return key.defaultValue
                }
                return url as! T

            default:
                // Attempt JSON decoding for Decodable types
                guard let decodableType = T.self as? any Decodable.Type else {
                    throw DecodingError.typeMismatch(
                        T.self,
                        DecodingError.Context(
                            codingPath: [],
                            debugDescription: "RemoteConfigKey type '\(T.self)' is not a supported primitive and does not conform to Decodable."
                        )
                    )
                }

                let data = configValue.dataValue
                let decoded = try JSONDecoder().decode(decodableType, from: data)
                guard let result = decoded as? T else {
                    return key.defaultValue
                }
                return result
            }
        } catch {
            throw FirebaseKitError.remoteConfigDecodingFailed(key: key.name, underlying: error)
        }
    }
}
