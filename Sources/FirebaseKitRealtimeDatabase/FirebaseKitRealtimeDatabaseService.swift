//
//  FirebaseKitRealtimeDatabaseService.swift
//  FirebaseKit
//
//  Created by Markus Mock on 22.02.26.
//

import Foundation
import FirebaseDatabase
import FirebaseKitCore

/// Concrete implementation of ``FirebaseKitRealtimeDatabaseServing`` backed by
/// Firebase Realtime Database.
///
/// Register this service after calling ``FirebaseKit/configure(_:)``:
///
/// ```swift
/// try FirebaseKit.configure(config)
/// FirebaseKitRealtimeDatabaseService.register()
/// ```
public final class FirebaseKitRealtimeDatabaseService: @unchecked Sendable, FirebaseKitRealtimeDatabaseServing {

    // MARK: - Properties

    private let database: Database
    private let lock = NSLock()
    private var activeHandles: [(DatabaseReference, UInt)] = []

    // MARK: - Init

    /// Creates the Realtime Database service.
    ///
    /// - Parameter database: The `Database` instance. Defaults to `Database.database()`.
    public init(database: Database = Database.database()) {
        self.database = database
    }

    deinit {
        for (ref, handle) in activeHandles {
            ref.removeObserver(withHandle: handle)
        }
    }

    // MARK: - Registration

    /// Registers this service into the ``FirebaseKitContainer``.
    ///
    /// Call this once after ``FirebaseKit/configure(_:)``.
    public static func register(database: Database = Database.database()) {
        let container = FirebaseKitContainer.shared
        guard let config = container.configuration else {
            fkError("Cannot register RealtimeDatabaseService: FirebaseKit is not configured.")
            return
        }
        guard config.modules.contains(.realtimeDatabase) else {
            fkInfo("RealtimeDatabase module is disabled — skipping registration.")
            return
        }

        let service = FirebaseKitRealtimeDatabaseService(database: database)
        container.registerRealtimeDatabase(service)
        fkInfo("RealtimeDatabaseService registered.")
    }

    // MARK: - FirebaseKitRealtimeDatabaseServing

    public func set(path: String, value: Any) async throws {
        let ref = database.reference(withPath: path)
        do {
            try await ref.setValue(value)
            fkDebug("Set value at '\(path)'.")
        } catch {
            throw FirebaseKitError.realtimeDBWriteFailed(path: path, underlying: error)
        }
    }

    public func update(path: String, values: [String: Any]) async throws {
        let ref = database.reference(withPath: path)
        do {
            try await ref.updateChildValues(values)
            fkDebug("Updated children at '\(path)'.")
        } catch {
            throw FirebaseKitError.realtimeDBWriteFailed(path: path, underlying: error)
        }
    }

    public func get<T: Decodable & Sendable>(path: RealtimeDBPath<T>) async throws -> T? {
        try await get(path: path.path, type: T.self)
    }

    public func get<T: Decodable & Sendable>(path: String, type: T.Type) async throws -> T? {
        let ref = database.reference(withPath: path)
        do {
            let snapshot = try await ref.getData()
            guard snapshot.exists() else {
                fkDebug("No data at '\(path)'.")
                return nil
            }
            return try decodeSnapshot(snapshot, path: path, type: type)
        } catch let error as FirebaseKitError {
            throw error
        } catch {
            throw FirebaseKitError.realtimeDBReadFailed(path: path, underlying: error)
        }
    }

    public func observe<T: Decodable & Sendable>(path: RealtimeDBPath<T>) -> AsyncStream<T?> {
        observe(path: path.path, type: T.self)
    }

    public func observe<T: Decodable & Sendable>(path: String, type: T.Type) -> AsyncStream<T?> {
        AsyncStream { [weak self] continuation in
            guard let self else {
                continuation.finish()
                return
            }

            let ref = self.database.reference(withPath: path)

            let handle = ref.observe(.value) { snapshot in
                guard snapshot.exists() else {
                    continuation.yield(nil)
                    return
                }

                do {
                    let value = try RealtimeDBDecoder.decode(snapshot: snapshot, type: type)
                    continuation.yield(value)
                } catch {
                    fkWarning("Observe decode error at '\(path)': \(error.localizedDescription)")
                    continuation.yield(nil)
                }
            }

            self.lock.lock()
            self.activeHandles.append((ref, handle))
            self.lock.unlock()

            continuation.onTermination = { [weak self] _ in
                ref.removeObserver(withHandle: handle)
                self?.removeHandle(ref: ref, handle: handle)
            }
        }
    }

    public func remove(path: String) async throws {
        let ref = database.reference(withPath: path)
        do {
            try await ref.removeValue()
            fkDebug("Removed data at '\(path)'.")
        } catch {
            throw FirebaseKitError.realtimeDBWriteFailed(path: path, underlying: error)
        }
    }

    // MARK: - Private

    private func decodeSnapshot<T: Decodable>(
        _ snapshot: DataSnapshot,
        path: String,
        type: T.Type
    ) throws -> T {
        do {
            return try RealtimeDBDecoder.decode(snapshot: snapshot, type: type)
        } catch {
            throw FirebaseKitError.realtimeDBDecodingFailed(path: path, underlying: error)
        }
    }

    private func removeHandle(ref: DatabaseReference, handle: UInt) {
        lock.lock()
        defer { lock.unlock() }
        activeHandles.removeAll { $0.0 === ref && $0.1 == handle }
    }
}
