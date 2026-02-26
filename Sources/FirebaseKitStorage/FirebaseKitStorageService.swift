//
//  FirebaseKitStorageService.swift
//  FirebaseKit
//
//  Created by Markus Mock on 22.02.26.
//

import Foundation
import FirebaseStorage
import FirebaseKitCore

/// Concrete implementation of ``FirebaseKitStorageServing`` backed by
/// Firebase Storage.
///
/// Register this service after calling ``FirebaseKit/configure(_:)``:
///
/// ```swift
/// try FirebaseKit.configure(config)
/// FirebaseKitStorageService.register()
/// ```
public final class FirebaseKitStorageService: @unchecked Sendable, FirebaseKitStorageServing {

    // MARK: - Properties

    private let storage: Storage

    // MARK: - Init

    /// Creates the storage service.
    ///
    /// - Parameter storage: The `Storage` instance. Defaults to `Storage.storage()`.
    public init(storage: Storage = Storage.storage()) {
        self.storage = storage
    }

    // MARK: - Registration

    /// Registers this service into the ``FirebaseKitContainer``.
    ///
    /// Call this once after ``FirebaseKit/configure(_:)``.
    public static func register(storage: Storage = Storage.storage()) {
        let container = FirebaseKitContainer.shared
        guard let config = container.configuration else {
            fkError("Cannot register StorageService: FirebaseKit is not configured.")
            return
        }
        guard config.modules.contains(.storage) else {
            fkInfo("Storage module is disabled — skipping registration.")
            return
        }

        let service = FirebaseKitStorageService(storage: storage)
        container.registerStorage(service)
        fkInfo("StorageService registered.")
    }

    // MARK: - FirebaseKitStorageServing

    @discardableResult
    public func upload(
        data: Data,
        to path: StoragePath,
        contentType: String?
    ) async throws -> StorageObjectMetadata {
        let ref = storage.reference(withPath: path.path)
        let metadata = StorageMetadata()
        if let contentType { metadata.contentType = contentType }

        do {
            let resultMetadata = try await ref.putDataAsync(data, metadata: metadata)
            fkDebug("Uploaded \(data.count) bytes to '\(path.path)'.")
            return resultMetadata.toKit(path: path.path)
        } catch {
            throw StorageErrorMapper.map(error, path: path.path, operation: .upload)
        }
    }

    @discardableResult
    public func upload(
        fileURL: URL,
        to path: StoragePath,
        contentType: String?
    ) async throws -> StorageObjectMetadata {
        let ref = storage.reference(withPath: path.path)
        let metadata = StorageMetadata()
        if let contentType { metadata.contentType = contentType }

        do {
            let resultMetadata = try await ref.putFileAsync(from: fileURL, metadata: metadata)
            fkDebug("Uploaded file '\(fileURL.lastPathComponent)' to '\(path.path)'.")
            return resultMetadata.toKit(path: path.path)
        } catch {
            throw StorageErrorMapper.map(error, path: path.path, operation: .upload)
        }
    }

    public func uploadWithProgress(
        data: Data,
        to path: StoragePath,
        contentType: String?
    ) -> AsyncStream<StorageTransferProgress> {
        AsyncStream { continuation in
            let ref = self.storage.reference(withPath: path.path)
            let metadata = StorageMetadata()
            if let contentType { metadata.contentType = contentType }

            let task = ref.putData(data, metadata: metadata)

            task.observe(.progress) { snapshot in
                guard let progress = snapshot.progress else { return }
                continuation.yield(
                    StorageTransferProgress(
                        bytesTransferred: progress.completedUnitCount,
                        totalBytes: progress.totalUnitCount
                    )
                )
            }

            task.observe(.success) { snapshot in
                if let progress = snapshot.progress {
                    continuation.yield(
                        StorageTransferProgress(
                            bytesTransferred: progress.completedUnitCount,
                            totalBytes: progress.totalUnitCount
                        )
                    )
                }
                continuation.finish()
            }

            task.observe(.failure) { _ in
                continuation.finish()
            }

            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }

    public func download(from path: StoragePath, maxSize: Int64) async throws -> Data {
        let ref = storage.reference(withPath: path.path)

        do {
            let data = try await ref.data(maxSize: maxSize)
            fkDebug("Downloaded \(data.count) bytes from '\(path.path)'.")
            return data
        } catch {
            throw StorageErrorMapper.map(error, path: path.path, operation: .download)
        }
    }

    public func downloadURL(for path: StoragePath) async throws -> URL {
        let ref = storage.reference(withPath: path.path)

        do {
            let url = try await ref.downloadURL()
            fkDebug("Got download URL for '\(path.path)'.")
            return url
        } catch {
            throw StorageErrorMapper.map(error, path: path.path, operation: .download)
        }
    }

    public func delete(at path: StoragePath) async throws {
        let ref = storage.reference(withPath: path.path)

        do {
            try await ref.delete()
            fkDebug("Deleted object at '\(path.path)'.")
        } catch {
            throw StorageErrorMapper.map(error, path: path.path, operation: .delete)
        }
    }

    public func metadata(for path: StoragePath) async throws -> StorageObjectMetadata {
        let ref = storage.reference(withPath: path.path)

        do {
            let meta = try await ref.getMetadata()
            return meta.toKit(path: path.path)
        } catch {
            throw StorageErrorMapper.map(error, path: path.path, operation: .download)
        }
    }
}

// MARK: - Metadata Mapping

private extension StorageMetadata {
    func toKit(path: String) -> StorageObjectMetadata {
        StorageObjectMetadata(
            path: path,
            name: name,
            size: size,
            contentType: contentType,
            timeCreated: timeCreated,
            updated: updated
        )
    }
}
