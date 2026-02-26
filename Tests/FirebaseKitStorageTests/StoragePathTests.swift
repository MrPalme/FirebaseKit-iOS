//
//  StoragePathTests.swift
//  FirebaseKit
//
//  Created by Markus Mock on 22.02.26.
//

import XCTest
@testable import FirebaseKitCore

final class StoragePathTests: XCTestCase {

    func testStoragePathStoresPath() {
        let path = StoragePath("users/abc/avatar.jpg")
        XCTAssertEqual(path.path, "users/abc/avatar.jpg")
    }

    func testStoragePathEquality() {
        let a = StoragePath("images/photo.png")
        let b = StoragePath("images/photo.png")
        let c = StoragePath("images/other.png")
        XCTAssertEqual(a, b)
        XCTAssertNotEqual(a, c)
    }

    func testStoragePathHashable() {
        let path1 = StoragePath("a/b/c")
        let path2 = StoragePath("a/b/c")
        let set: Set<StoragePath> = [path1, path2]
        XCTAssertEqual(set.count, 1)
    }

    func testStorageObjectMetadataInit() {
        let meta = StorageObjectMetadata(
            path: "test/file.txt",
            name: "file.txt",
            size: 1024,
            contentType: "text/plain",
            timeCreated: nil,
            updated: nil
        )
        XCTAssertEqual(meta.path, "test/file.txt")
        XCTAssertEqual(meta.name, "file.txt")
        XCTAssertEqual(meta.size, 1024)
        XCTAssertEqual(meta.contentType, "text/plain")
    }

    func testTransferProgressFractionCompleted() {
        let progress = StorageTransferProgress(bytesTransferred: 50, totalBytes: 100)
        XCTAssertEqual(progress.fractionCompleted, 0.5, accuracy: 0.001)
    }

    func testTransferProgressZeroTotal() {
        let progress = StorageTransferProgress(bytesTransferred: 0, totalBytes: 0)
        XCTAssertEqual(progress.fractionCompleted, 0.0)
    }

    func testTransferProgressNegativeTotal() {
        let progress = StorageTransferProgress(bytesTransferred: 0, totalBytes: -1)
        XCTAssertEqual(progress.fractionCompleted, 0.0)
    }
}
