//
//  AuthErrorMapper.swift
//  FirebaseKit
//
//  Created by Markus Mock on 22.02.26.
//

import Foundation
import FirebaseAuth
import FirebaseKitCore

/// Maps Firebase Auth errors to ``FirebaseKitError`` cases.
enum AuthErrorMapper {

    /// Maps a raw `Error` (typically `NSError` from FirebaseAuth) into
    /// the appropriate ``FirebaseKitError`` case.
    static func map(_ error: Error) -> FirebaseKitError {
        let nsError = error as NSError

        guard nsError.domain == AuthErrorDomain else {
            return .authFailure(underlying: error)
        }

        let code = AuthErrorCode(rawValue: nsError.code)

        switch code {
        case .wrongPassword, .invalidCredential:
            return .authInvalidCredentials(underlying: error)
        case .userNotFound:
            return .authUserNotFound(underlying: error)
        case .emailAlreadyInUse:
            return .authEmailAlreadyInUse(underlying: error)
        case .weakPassword:
            return .authWeakPassword(underlying: error)
        default:
            return .authFailure(underlying: error)
        }
    }
}
