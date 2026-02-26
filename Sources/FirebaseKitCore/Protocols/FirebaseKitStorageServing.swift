//
//  FirebaseKitStorageServing.swift
//  FirebaseKit
//
//  Created by Markus Mock on 22.02.26.
//

import Foundation

// MARK: - Storage Path

/// A typed reference to a location in Firebase Storage.
///
/// Host apps define stable storage paths as static properties, giving
/// compile-time safety for upload / download targets.
///
/// ```swift
/// extension StoragePath {
///     static func userAvatar(uid: String) -> StoragePath {
///         StoragePath("users/\(uid)/avatar.jpg")
///     }
///     static func documentAttachment(docId: String, name: String) -> StoragePath {
///         StoragePath("documents/\(docId)/\(name)")
///     }
/// }
/// ```
public struct StoragePath: Sendable, Hashable {
    /// The full path in the storage bucket (e.g. `"users/abc/avatar.jpg"`).
    public let path: String

    /// Creates a storage path.
    ///
    /// - Parameter path: The full path within the storage bucket.
    public init(_ path: String) {
        self.path = path
    }
}

// MARK: - Storage Metadata

/// Metadata associated with a storage object.
public struct StorageObjectMetadata: Sendable {
    /// The full path of the object.
    public let path: String
    /// The object's name (last path component).
    public let name: String?
    /// The object's size in bytes.
    public let size: Int64
    /// The MIME content type.
    public let contentType: String?
    /// When the object was created.
    public let timeCreated: Date?
    /// When the object was last updated.
    public let updated: Date?

    public init(
        path: String,
        name: String?,
        size: Int64,
        contentType: String?,
        timeCreated: Date?,
        updated: Date?
    ) {
        self.path = path
        self.name = name
        self.size = size
        self.contentType = contentType
        self.timeCreated = timeCreated
        self.updated = updated
    }
}

// MARK: - Upload Progress

/// Represents the progress of a storage upload or download operation.
public struct StorageTransferProgress: Sendable {
    /// Bytes transferred so far.
    public let bytesTransferred: Int64
    /// Total bytes expected (-1 if unknown).
    public let totalBytes: Int64
    /// Fraction complete (0.0–1.0). Returns 0 if total is unknown.
    public var fractionCompleted: Double {
        guard totalBytes > 0 else { return 0 }
        return Double(bytesTransferred) / Double(totalBytes)
    }

    public init(bytesTransferred: Int64, totalBytes: Int64) {
        self.bytesTransferred = bytesTransferred
        self.totalBytes = totalBytes
    }
}

// MARK: - Protocol

/// Contract for the FirebaseKit Storage service.
///
/// The concrete implementation lives in `FirebaseKitStorage`.
public protocol FirebaseKitStorageServing: Sendable {

    /// Uploads raw data to the given storage path.
    ///
    /// - Parameters:
    ///   - data: The data to upload.
    ///   - path: The destination ``StoragePath``.
    ///   - contentType: Optional MIME type (e.g. `"image/jpeg"`).
    /// - Returns: The ``StorageObjectMetadata`` of the uploaded object.
    /// - Throws: ``FirebaseKitError`` on failure.
    @discardableResult
    func upload(
        data: Data,
        to path: StoragePath,
        contentType: String?
    ) async throws -> StorageObjectMetadata

    /// Uploads a local file to the given storage path.
    ///
    /// - Parameters:
    ///   - fileURL: The local file URL.
    ///   - path: The destination ``StoragePath``.
    ///   - contentType: Optional MIME type.
    /// - Returns: The ``StorageObjectMetadata`` of the uploaded object.
    /// - Throws: ``FirebaseKitError`` on failure.
    @discardableResult
    func upload(
        fileURL: URL,
        to path: StoragePath,
        contentType: String?
    ) async throws -> StorageObjectMetadata

    /// Uploads data with progress reporting.
    ///
    /// - Parameters:
    ///   - data: The data to upload.
    ///   - path: The destination ``StoragePath``.
    ///   - contentType: Optional MIME type.
    /// - Returns: An ``AsyncStream`` of ``StorageTransferProgress`` updates.
    ///   The stream completes when the upload finishes.
    func uploadWithProgress(
        data: Data,
        to path: StoragePath,
        contentType: String?
    ) -> AsyncStream<StorageTransferProgress>

    /// Downloads data from the given storage path.
    ///
    /// - Parameters:
    ///   - path: The ``StoragePath`` to download from.
    ///   - maxSize: Maximum size in bytes. Defaults to 10 MB.
    /// - Returns: The downloaded data.
    /// - Throws: ``FirebaseKitError`` on failure.
    func download(from path: StoragePath, maxSize: Int64) async throws -> Data

    /// Retrieves the publicly accessible download URL for the given path.
    ///
    /// - Parameter path: The ``StoragePath``.
    /// - Returns: The download `URL`.
    /// - Throws: ``FirebaseKitError`` on failure.
    func downloadURL(for path: StoragePath) async throws -> URL

    /// Deletes the object at the given storage path.
    ///
    /// - Parameter path: The ``StoragePath`` to delete.
    /// - Throws: ``FirebaseKitError`` on failure.
    func delete(at path: StoragePath) async throws

    /// Retrieves metadata for the object at the given storage path.
    ///
    /// - Parameter path: The ``StoragePath``.
    /// - Returns: The ``StorageObjectMetadata``.
    /// - Throws: ``FirebaseKitError`` on failure.
    func metadata(for path: StoragePath) async throws -> StorageObjectMetadata
}

/// Default parameter values for ``FirebaseKitStorageServing``.
public extension FirebaseKitStorageServing {

    /// Convenience overload with `contentType` defaulting to `nil`.
    @discardableResult
    func upload(data: Data, to path: StoragePath) async throws -> StorageObjectMetadata {
        try await upload(data: data, to: path, contentType: nil)
    }

    /// Convenience overload with `contentType` defaulting to `nil`.
    @discardableResult
    func upload(fileURL: URL, to path: StoragePath) async throws -> StorageObjectMetadata {
        try await upload(fileURL: fileURL, to: path, contentType: nil)
    }

    /// Convenience overload with `contentType` defaulting to `nil`.
    func uploadWithProgress(data: Data, to path: StoragePath) -> AsyncStream<StorageTransferProgress> {
        uploadWithProgress(data: data, to: path, contentType: nil)
    }

    /// Convenience overload with `maxSize` defaulting to 10 MB.
    func download(from path: StoragePath) async throws -> Data {
        try await download(from: path, maxSize: 10 * 1024 * 1024)
    }
}
