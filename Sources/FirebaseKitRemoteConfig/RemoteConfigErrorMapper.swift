//
//  RemoteConfigErrorMapper.swift
//  FirebaseKit
//
//  Created by Markus Mock on 22.02.26.
//

import Foundation
import FirebaseRemoteConfig
import FirebaseKitCore

/// Maps Firebase Remote Config errors to ``FirebaseKitError`` cases.
enum RemoteConfigErrorMapper {

    static func map(_ error: Error) -> FirebaseKitError {
        let nsError = error as NSError

        // Check for throttling via the NSError code directly
        // RemoteConfigError.Code.throttled.rawValue == 8001
        if nsError.domain == RemoteConfigErrorDomain, nsError.code == 8001 {
            return .remoteConfigThrottled(underlying: error)
        }

        return .remoteConfigFetchFailed(underlying: error)
    }
}
