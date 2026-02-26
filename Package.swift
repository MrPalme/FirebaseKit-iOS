// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FirebaseKit-iOS",
    platforms: [
        .iOS(.v16),
        .macOS(.v13)
    ],
    products: [
        // Core module — Foundation-only contracts, shared types, error types, logging, strings, DI.
        .library(name: "FirebaseKitCore", targets: ["FirebaseKitCore"]),

        // Auth module — FirebaseAuth wrapper behind protocols.
        .library(name: "FirebaseKitAuth", targets: ["FirebaseKitAuth"]),

        // Remote Config module — Typed keys and decoding.
        .library(name: "FirebaseKitRemoteConfig", targets: ["FirebaseKitRemoteConfig"]),

        // Messaging module — FCM wrapper, token handling, APNs bridging.
        .library(name: "FirebaseKitMessaging", targets: ["FirebaseKitMessaging"]),

        // Firestore module — CRUD wrappers with host-app model mapping.
        .library(name: "FirebaseKitFirestore", targets: ["FirebaseKitFirestore"]),

        // Storage module — Upload, download, delete, metadata.
        .library(name: "FirebaseKitStorage", targets: ["FirebaseKitStorage"]),

        // Realtime Database module — Read, write, observe.
        .library(name: "FirebaseKitRealtimeDatabase", targets: ["FirebaseKitRealtimeDatabase"]),

        // Analytics module — Event logging, screen tracking, SwiftUI modifiers.
        .library(name: "FirebaseKitAnalytics", targets: ["FirebaseKitAnalytics"]),
    ],
    dependencies: [
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "11.0.0"),
    ],
    targets: [
        // MARK: - Core

        .target(
            name: "FirebaseKitCore",
            dependencies: [],
            path: "Sources/FirebaseKitCore"
        ),

        // MARK: - Auth

        .target(
            name: "FirebaseKitAuth",
            dependencies: [
                "FirebaseKitCore",
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
            ],
            path: "Sources/FirebaseKitAuth"
        ),

        // MARK: - Remote Config

        .target(
            name: "FirebaseKitRemoteConfig",
            dependencies: [
                "FirebaseKitCore",
                .product(name: "FirebaseRemoteConfig", package: "firebase-ios-sdk"),
            ],
            path: "Sources/FirebaseKitRemoteConfig"
        ),

        // MARK: - Messaging

        .target(
            name: "FirebaseKitMessaging",
            dependencies: [
                "FirebaseKitCore",
                .product(name: "FirebaseMessaging", package: "firebase-ios-sdk"),
            ],
            path: "Sources/FirebaseKitMessaging"
        ),

        // MARK: - Firestore

        .target(
            name: "FirebaseKitFirestore",
            dependencies: [
                "FirebaseKitCore",
                .product(name: "FirebaseFirestore", package: "firebase-ios-sdk"),
            ],
            path: "Sources/FirebaseKitFirestore"
        ),

        // MARK: - Storage

        .target(
            name: "FirebaseKitStorage",
            dependencies: [
                "FirebaseKitCore",
                .product(name: "FirebaseStorage", package: "firebase-ios-sdk"),
            ],
            path: "Sources/FirebaseKitStorage"
        ),

        // MARK: - Realtime Database

        .target(
            name: "FirebaseKitRealtimeDatabase",
            dependencies: [
                "FirebaseKitCore",
                .product(name: "FirebaseDatabase", package: "firebase-ios-sdk"),
            ],
            path: "Sources/FirebaseKitRealtimeDatabase"
        ),

        // MARK: - Analytics

        .target(
            name: "FirebaseKitAnalytics",
            dependencies: [
                "FirebaseKitCore",
                .product(name: "FirebaseAnalytics", package: "firebase-ios-sdk"),
            ],
            path: "Sources/FirebaseKitAnalytics"
        ),

        // MARK: - Tests

        .testTarget(
            name: "FirebaseKitCoreTests",
            dependencies: ["FirebaseKitCore"],
            path: "Tests/FirebaseKitCoreTests"
        ),

        .testTarget(
            name: "FirebaseKitAuthTests",
            dependencies: ["FirebaseKitAuth", "FirebaseKitCore"],
            path: "Tests/FirebaseKitAuthTests"
        ),

        .testTarget(
            name: "FirebaseKitRemoteConfigTests",
            dependencies: ["FirebaseKitRemoteConfig", "FirebaseKitCore"],
            path: "Tests/FirebaseKitRemoteConfigTests"
        ),

        .testTarget(
            name: "FirebaseKitMessagingTests",
            dependencies: ["FirebaseKitMessaging", "FirebaseKitCore"],
            path: "Tests/FirebaseKitMessagingTests"
        ),

        .testTarget(
            name: "FirebaseKitFirestoreTests",
            dependencies: ["FirebaseKitFirestore", "FirebaseKitCore"],
            path: "Tests/FirebaseKitFirestoreTests"
        ),

        .testTarget(
            name: "FirebaseKitStorageTests",
            dependencies: ["FirebaseKitStorage", "FirebaseKitCore"],
            path: "Tests/FirebaseKitStorageTests"
        ),

        .testTarget(
            name: "FirebaseKitRealtimeDatabaseTests",
            dependencies: ["FirebaseKitRealtimeDatabase", "FirebaseKitCore"],
            path: "Tests/FirebaseKitRealtimeDatabaseTests"
        ),

        .testTarget(
            name: "FirebaseKitAnalyticsTests",
            dependencies: ["FirebaseKitAnalytics", "FirebaseKitCore"],
            path: "Tests/FirebaseKitAnalyticsTests"
        ),
    ]
)
