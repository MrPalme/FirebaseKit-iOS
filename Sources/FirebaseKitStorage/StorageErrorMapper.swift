//
//  StorageErrorMapper.swift
//  FirebaseKit
//
//  Created by Markus Mock on 22.02.26.
//

import Foundation
import FirebaseStorage
import FirebaseKitCore

/// Maps Firebase Storage errors to ``FirebaseKitError`` cases.
enum StorageErrorMapper {

    enum Operation {
        case upload
        case download
        case delete
    }

    /// Maps a raw `Error` into the appropriate ``FirebaseKitError`` case.
    static func map(_ error: Error, path: String, operation: Operation) -> FirebaseKitError {
        let nsError = error as NSError

        guard nsError.domain == StorageErrorDomain else {
            return mapByOperation(error, path: path, operation: operation)
        }

        let code = StorageErrorCode(rawValue: nsError.code)

        switch code {
        case .objectNotFound, .bucketNotFound:
            return .storageObjectNotFound(path: path)
        case .unauthorized, .unauthenticated:
            return .storagePermissionDenied(path: path, underlying: error)
        case .cancelled:
            return .storageCancelled(path: path)
        default:
            return mapByOperation(error, path: path, operation: operation)
        }
    }

    private static func mapByOperation(_ error: Error, path: String, operation: Operation) -> FirebaseKitError {
        switch operation {
        case .upload:
            return .storageUploadFailed(path: path, underlying: error)
        case .download:
            return .storageDownloadFailed(path: path, underlying: error)
        case .delete:
            return .storageDeleteFailed(path: path, underlying: error)
        }
    }
}
