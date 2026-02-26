# FirebaseKit-iOS

A modular, app-agnostic Firebase abstraction layer for iOS (Swift 5.9+). Designed for SwiftUI-first apps but fully usable from UIKit.
FirebaseKit handles initialization, typed access, consistent error mapping, and reusable integration logic. Host apps handle UI, configuration values, model mapping, and app-specific interpretation.

## Modules

- **FirebaseKitCore** — Foundation-only contracts, shared types, error types, logging, string provider, and dependency container. No Firebase SDK dependency.
- **FirebaseKitAuth** — FirebaseAuth wrapper behind protocols. Exposes session state via `AsyncStream` and `@MainActor ObservableObject`.
- **FirebaseKitRemoteConfig** — Remote Config wrapper with typed keys (`RemoteConfigKey<T>`) and automatic decoding for Bool, Int, Double, String, URL, and Decodable JSON.
- **FirebaseKitMessaging** — FCM wrapper with token handling, APNs bridging hooks, and topic subscription.
- **FirebaseKitFirestore** — Firestore CRUD wrappers with model mapping fully delegated to the host app via encode/decode closures.
- **FirebaseKitStorage** — Upload, download, delete, and metadata for Firebase Storage. Typed `StoragePath` for compile-time safe references. Progress tracking via `AsyncStream`.
- **FirebaseKitRealtimeDatabase** — Read, write, observe for Firebase Realtime Database. Typed `RealtimeDBPath<T>` for compile-time safe paths. Continuous observation via `AsyncStream`.
- **FirebaseKitAnalytics** — Event logging and screen tracking for Firebase Analytics. Host-app-defined events and screens via `AnalyticsEvent` / `AnalyticsScreen` protocols. SwiftUI modifiers (`.trackScreen`, `.trackTap`) and UIKit extensions included.

## Requirements

- iOS 16+ / macOS 13+
- Swift 5.9+
- Firebase iOS SDK 11.0+

## Installation

Add FirebaseKit-iOS to your project via Swift Package Manager:

```swift
// In your Package.swift or Xcode project:
.package(url: "https://github.com/your-org/FirebaseKit-iOS.git", from: "1.0.0")
```

Then add the modules you need as dependencies:

```swift
.target(
    name: "YourApp",
    dependencies: [
        "FirebaseKitCore",
        "FirebaseKitAuth",
        "FirebaseKitRemoteConfig",
        "FirebaseKitMessaging",
        "FirebaseKitFirestore",
        "FirebaseKitStorage",
        "FirebaseKitRealtimeDatabase",
        "FirebaseKitAnalytics",
    ]
)
```

## Setup

### 1. Configure Firebase (Host App Responsibility)

Your app must call `FirebaseApp.configure()` before configuring FirebaseKit. Include your `GoogleService-Info.plist` in your app target.

### 2. Configure FirebaseKit

```swift
import FirebaseCore
import FirebaseKitCore
import FirebaseKitAuth
import FirebaseKitRemoteConfig
import FirebaseKitMessaging
import FirebaseKitFirestore
import FirebaseKitStorage
import FirebaseKitRealtimeDatabase
import FirebaseKitAnalytics

@main
struct MyApp: App {
    init() {
        FirebaseApp.configure()

        do {
            try FirebaseKit.configure(
                FirebaseKitConfiguration(
                    environment: .debug,
                    modules: .all,
                    stringProvider: FirebaseKitDefaultStrings(),
                    logger: FirebaseKitConsoleLogger(minimumLevel: .debug)
                )
            )
        } catch {
            fatalError("FirebaseKit configuration failed: \(error)")
        }

        // Register each module
        FirebaseKitAuthService.register()
        FirebaseKitRemoteConfigService.register(defaults: [
            "feature_enabled": true as NSObject,
        ])
        FirebaseKitMessagingService.register()
        FirebaseKitFirestoreService.register()
        FirebaseKitStorageService.register()
        FirebaseKitRealtimeDatabaseService.register()
        FirebaseKitAnalyticsService.register()
    }

    var body: some Scene {
        WindowGroup { ContentView() }
    }
}
```

### 3. Selective Module Usage

Only import and register the modules you need:

```swift
try FirebaseKit.configure(
    FirebaseKitConfiguration(
        environment: .production,
        modules: [.auth, .remoteConfig, .analytics]  // Only these three
    )
)

FirebaseKitAuthService.register()
FirebaseKitRemoteConfigService.register()
FirebaseKitAnalyticsService.register()
// Other modules are not registered — accessing them will fatalError with a clear message.
```

## Usage Examples

### Auth: Session State in a ViewModel

```swift
import FirebaseKitCore
import FirebaseKitAuth

struct ContentView: View {
    @StateObject private var auth = AuthSessionObserver(service: FirebaseKit.auth)

    var body: some View {
        switch auth.session.state {
        case .signedOut:
            LoginView()
        case .signedIn:
            HomeView(user: auth.session.user!)
        }
    }
}
```

### Auth: Sign In

```swift
@MainActor
final class LoginViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var errorMessage: String?

    func signIn() async {
        do {
            try await FirebaseKit.auth.signIn(email: email, password: password)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
```

### Remote Config: Typed Keys

```swift
// Define typed keys
extension RemoteConfigKey where T == Bool {
    static let onboardingEnabled = RemoteConfigKey<Bool>("onboarding_enabled", default: false)
}

extension RemoteConfigKey where T == Int {
    static let maxUploadSizeMB = RemoteConfigKey<Int>("max_upload_size_mb", default: 10)
}

// Use them
try await FirebaseKit.remoteConfig.fetchAndActivate()
let enabled = try FirebaseKit.remoteConfig.value(for: .onboardingEnabled)
let maxSize = try FirebaseKit.remoteConfig.value(for: .maxUploadSizeMB)
```

### Remote Config: Observe Updates

```swift
Task {
    for await _ in FirebaseKit.remoteConfig.configUpdateStream {
        // Config was updated — re-read values
        let enabled = try? FirebaseKit.remoteConfig.value(for: .onboardingEnabled)
        print("Onboarding is now: \(enabled ?? false)")
    }
}
```

### Messaging: AppDelegate Hooks

```swift
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        FirebaseKit.messaging.setAPNSToken(deviceToken)
    }

    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        let result = FirebaseKit.messaging.handleRemoteNotification(userInfo)
        completionHandler(result == .handled ? .newData : .noData)
    }
}
```

### Messaging: Observe FCM Token

```swift
Task {
    for await token in FirebaseKit.messaging.fcmTokenStream {
        guard let token else { continue }
        // Send token to your backend
        try await api.registerDeviceToken(token)
    }
}
```

### Firestore: Read a Document

```swift
struct UserProfile {
    let id: String
    let name: String
    let email: String
}

let profile = try await FirebaseKit.firestore.getDocument(
    path: "users/\(uid)",
    as: UserProfile.self,
    decode: { snapshot in
        guard let data = snapshot.data else {
            throw NSError(domain: "App", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data"])
        }
        return UserProfile(
            id: snapshot.documentID,
            name: data["name"] as? String ?? "",
            email: data["email"] as? String ?? ""
        )
    }
)
```

### Firestore: Write a Document

```swift
try await FirebaseKit.firestore.setDocument(
    path: "users/\(uid)",
    value: profile,
    encode: { profile in
        ["name": profile.name, "email": profile.email]
    }
)
```

### Firestore: Query with Filters

```swift
let recentNotes = try await FirebaseKit.firestore.query(
    collectionPath: "users/\(uid)/notes",
    build: { query in
        query
            .whereField("archived", isEqualTo: false)
            .order(by: "createdAt", descending: true)
            .limit(to: 20)
    },
    decode: { snapshot in
        Note(
            id: snapshot.documentID,
            title: snapshot.data?["title"] as? String ?? "",
            body: snapshot.data?["body"] as? String ?? ""
        )
    }
)
```

### Storage: Upload and Download

```swift
// Define typed storage paths
extension StoragePath {
    static func userAvatar(uid: String) -> StoragePath {
        StoragePath("users/\(uid)/avatar.jpg")
    }
}

// Upload data
let imageData = /* your image data */
let metadata = try await FirebaseKit.storage.upload(
    data: imageData,
    to: .userAvatar(uid: uid),
    contentType: "image/jpeg"
)

// Upload from file URL
try await FirebaseKit.storage.upload(
    fileURL: localFileURL,
    to: StoragePath("documents/\(docId)/attachment.pdf"),
    contentType: "application/pdf"
)

// Get download URL
let url = try await FirebaseKit.storage.downloadURL(for: .userAvatar(uid: uid))

// Download data
let data = try await FirebaseKit.storage.download(from: .userAvatar(uid: uid))

// Delete
try await FirebaseKit.storage.delete(at: .userAvatar(uid: uid))
```

### Storage: Upload with Progress

```swift
for await progress in FirebaseKit.storage.uploadWithProgress(data: largeData, to: path) {
    print("Upload: \(Int(progress.fractionCompleted * 100))%")
}
```

### Realtime Database: Read and Write

```swift
// Define typed paths
extension RealtimeDBPath where T == String {
    static func userStatus(uid: String) -> RealtimeDBPath<String> {
        RealtimeDBPath("users/\(uid)/status")
    }
}

// Write a value
try await FirebaseKit.realtimeDatabase.set(
    path: "users/\(uid)/status",
    value: "online"
)

// Update specific children
try await FirebaseKit.realtimeDatabase.update(
    path: "users/\(uid)",
    values: ["status": "online", "lastSeen": Date().timeIntervalSince1970]
)

// Read a typed value
let status = try await FirebaseKit.realtimeDatabase.get(
    path: .userStatus(uid: uid)
)

// Read a complex Decodable type
struct UserProfile: Decodable {
    let name: String
    let age: Int
}

let profile = try await FirebaseKit.realtimeDatabase.get(
    path: RealtimeDBPath<UserProfile>("users/\(uid)/profile")
)

// Remove data
try await FirebaseKit.realtimeDatabase.remove(path: "users/\(uid)/temp")
```

### Realtime Database: Observe Changes

```swift
let statusPath = RealtimeDBPath<String>("users/\(uid)/status")

Task {
    for await status in FirebaseKit.realtimeDatabase.observe(path: statusPath) {
        print("Status changed: \(status ?? "nil")")
    }
}
```

### Analytics: Define Host-App Events and Screens

```swift
import FirebaseKitCore

// Define your screens (host-app owned)
enum AppScreen: String, AnalyticsScreen {
    case home, settings, profile, onboarding

    var screenName: String { rawValue }
}

// Define your events (host-app owned)
enum AppEvent: AnalyticsEvent {
    case buttonTapped(name: String, screen: String)
    case purchaseCompleted(productId: String, price: Double)
    case searchPerformed(query: String, resultCount: Int)

    var name: String {
        switch self {
        case .buttonTapped: return "button_tapped"
        case .purchaseCompleted: return "purchase_completed"
        case .searchPerformed: return "search_performed"
        }
    }

    var parameters: [String: AnalyticsValue] {
        switch self {
        case .buttonTapped(let name, let screen):
            return ["button_name": .string(name), "screen": .string(screen)]
        case .purchaseCompleted(let productId, let price):
            return ["product_id": .string(productId), "price": .double(price)]
        case .searchPerformed(let query, let resultCount):
            return ["query": .string(query), "result_count": .int(resultCount)]
        }
    }
}
```

### Analytics: Direct Logging

```swift
// Log an event
FirebaseKit.analytics.log(event: AppEvent.buttonTapped(name: "upgrade", screen: "settings"))

// Log a screen view
FirebaseKit.analytics.screen(AppScreen.home)

// Set user properties (never PII!)
FirebaseKit.analytics.setUserProperty("subscription_tier", value: "premium")

// Set user ID (use opaque IDs only, never emails!)
FirebaseKit.analytics.setUserId("user_abc123")
```

### Analytics: SwiftUI Modifiers

```swift
import FirebaseKitAnalytics

struct HomeView: View {
    var body: some View {
        VStack {
            Text("Welcome!")

            Button("Upgrade") {
                // your action
            }
            // Logs AppEvent when tapped (does not interfere with button action)
            .trackTap(AppEvent.buttonTapped(name: "upgrade", screen: "home"))

            Button("Settings") {
                // navigate
            }
            .trackTap(AppEvent.buttonTapped(name: "settings", screen: "home"))
        }
        // Logs screen_view when this view appears
        .trackScreen(AppScreen.home)
        // Sets screen context in SwiftUI environment
        .analyticsContext(screen: AppScreen.home)
    }
}
```

> **Note on `onAppear` double-fires:** SwiftUI's `onAppear` may fire more than once during navigation transitions. The `.trackScreen` modifier deduplicates by default (only the first `onAppear` fires the event). Pass `deduplicate: false` to log every appearance.

### Analytics: UIKit Usage

```swift
import FirebaseKitAnalytics

class ProfileViewController: UIViewController {
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        trackScreen(AppScreen.profile) // UIViewController extension
    }

    func setupButtons() {
        upgradeButton.trackTap(
            AppEvent.buttonTapped(name: "upgrade", screen: "profile")
        )
    }
}
```

## Customization

### Custom String Provider

Override user-facing strings (for localization or branding):

```swift
struct AppStrings: FirebaseKitStringProviding {
    func string(_ key: FirebaseKitStringKey) -> String {
        switch key {
        case .authInvalidCredentials:
            return NSLocalizedString("auth.invalidCredentials", comment: "")
        default:
            return FirebaseKitDefaultStrings().string(key)
        }
    }
}

// Pass to configuration
FirebaseKitConfiguration(stringProvider: AppStrings())
```

### Custom Logger

Inject your own logging implementation:

```swift
struct AppLogger: FirebaseKitLogging {
    let minimumLevel: FirebaseKitLogLevel = .info

    func log(
        _ level: FirebaseKitLogLevel,
        _ message: @autoclosure () -> String,
        file: String,
        function: String,
        line: UInt
    ) {
        // Forward to your analytics/crash reporting/custom logger
        MyAnalytics.log(level: level.rawValue, message: message())
    }
}

FirebaseKitConfiguration(logger: AppLogger())
```

## Error Handling

All errors are mapped to `FirebaseKitError`, a stable domain error type:

```swift
do {
    try await FirebaseKit.auth.signIn(email: email, password: password)
} catch let error as FirebaseKitError {
    switch error {
    case .authInvalidCredentials:
        showAlert("Wrong email or password.")
    case .authUserNotFound:
        showAlert("No account found.")
    case .authEmailAlreadyInUse:
        showAlert("Email already taken.")
    default:
        showAlert(error.localizedDescription)
    }
}
```

Each error case carries an `underlying: Error` with the original Firebase SDK error for debugging.

### Storage Errors

| Case | When |
|------|------|
| `storageUploadFailed(path:underlying:)` | Upload operation failed |
| `storageDownloadFailed(path:underlying:)` | Download operation failed |
| `storageDeleteFailed(path:underlying:)` | Delete operation failed |
| `storageObjectNotFound(path:)` | Object does not exist |
| `storagePermissionDenied(path:underlying:)` | Security rules denied access |
| `storageCancelled(path:)` | Operation was cancelled |
| `storageOperationFailed(underlying:)` | Generic storage failure |

### Realtime Database Errors

| Case | When |
|------|------|
| `realtimeDBReadFailed(path:underlying:)` | Read/get operation failed |
| `realtimeDBWriteFailed(path:underlying:)` | Set/update/remove failed |
| `realtimeDBDecodingFailed(path:underlying:)` | Value could not be decoded to expected type |
| `realtimeDBOperationFailed(underlying:)` | Generic database failure |

### Analytics Errors

| Case | When |
|------|------|
| `analyticsFailure(underlying:)` | Analytics operation failed |

## Privacy Note

**Never log PII (Personally Identifiable Information) through analytics:**
- Do not pass email addresses, phone numbers, or full names as event parameters.
- Use opaque, stable identifiers for `setUserId(_:)` (e.g. Firebase Auth UID).
- Review `AnalyticsEvent` parameters before shipping to ensure no PII leaks.
- Firebase Analytics automatically collects device-level data. Review [Firebase data collection](https://firebase.google.com/docs/analytics/configure-data-collection) for details.

## Architecture

```
Host App
  │
  ├── FirebaseKitCore (protocols, types, errors, DI container)
  │     ├── FirebaseKitAuthServing (protocol)
  │     ├── FirebaseKitRemoteConfigServing (protocol)
  │     ├── FirebaseKitMessagingServing (protocol)
  │     ├── FirebaseKitFirestoreServing (protocol)
  │     ├── FirebaseKitStorageServing (protocol)
  │     ├── FirebaseKitRealtimeDatabaseServing (protocol)
  │     └── FirebaseKitAnalyticsServing (protocol)
  │
  ├── FirebaseKitAuth (concrete Firebase Auth implementation)
  ├── FirebaseKitRemoteConfig (concrete Remote Config implementation)
  ├── FirebaseKitMessaging (concrete FCM implementation)
  ├── FirebaseKitFirestore (concrete Firestore implementation)
  ├── FirebaseKitStorage (concrete Storage implementation)
  ├── FirebaseKitRealtimeDatabase (concrete Realtime Database implementation)
  └── FirebaseKitAnalytics (concrete Analytics implementation + SwiftUI modifiers + UIKit extensions)
```

- Protocols live in `FirebaseKitCore` (no Firebase SDK dependency).
- Concrete implementations live in feature modules (depend on Firebase SDK).
- The `FirebaseKit` enum in Core is the single facade entry point.
- `FirebaseKitContainer` holds registered service instances.
- Host apps interact only with protocols and the facade.

## Threading

- UI-facing state updates (`AuthSessionObserver`, etc.) are `@MainActor`.
- Service calls (`signIn`, `fetchAndActivate`, `getDocument`, `upload`, `get`, etc.) are `async` and can run off-main.
- All service classes are `Sendable`-safe with internal locking.
- `AsyncStream` observers (Realtime Database, Remote Config, Auth) clean up handles on task cancellation.

## Project Structure

```
FirebaseKit-iOS/
├── Package.swift
├── LICENSE
├── README.md
├── Sources/
│   ├── FirebaseKitCore/
│   │   ├── FirebaseKit.swift                        (facade)
│   │   ├── FirebaseKitConfiguration.swift
│   │   ├── FirebaseKitContainer.swift               (DI container)
│   │   ├── FirebaseKitEnvironment.swift
│   │   ├── FirebaseKitError.swift
│   │   ├── FirebaseKitLogging.swift
│   │   ├── FirebaseKitStringProviding.swift
│   │   ├── LogHelper.swift
│   │   └── Protocols/
│   │       ├── FirebaseKitAuthServing.swift
│   │       ├── FirebaseKitRemoteConfigServing.swift
│   │       ├── FirebaseKitMessagingServing.swift
│   │       ├── FirebaseKitFirestoreServing.swift
│   │       ├── FirebaseKitStorageServing.swift
│   │       ├── FirebaseKitRealtimeDatabaseServing.swift
│   │       └── FirebaseKitAnalyticsServing.swift
│   ├── FirebaseKitAuth/
│   │   ├── FirebaseKitAuthService.swift
│   │   ├── AuthErrorMapper.swift
│   │   └── AuthSessionObserver.swift
│   ├── FirebaseKitRemoteConfig/
│   │   ├── FirebaseKitRemoteConfigService.swift
│   │   ├── RemoteConfigValueDecoder.swift
│   │   └── RemoteConfigErrorMapper.swift
│   ├── FirebaseKitMessaging/
│   │   └── FirebaseKitMessagingService.swift
│   ├── FirebaseKitFirestore/
│   │   ├── FirebaseKitFirestoreService.swift
│   │   └── FirebaseKitQuery+Firestore.swift
│   ├── FirebaseKitStorage/
│   │   ├── FirebaseKitStorageService.swift
│   │   └── StorageErrorMapper.swift
│   ├── FirebaseKitRealtimeDatabase/
│   │   ├── FirebaseKitRealtimeDatabaseService.swift
│   │   └── RealtimeDBDecoder.swift
│   └── FirebaseKitAnalytics/
│       ├── FirebaseKitAnalyticsService.swift
│       ├── AnalyticsSwiftUIModifiers.swift
│       └── AnalyticsUIKitExtensions.swift
├── Tests/
│   ├── FirebaseKitCoreTests/
│   │   ├── FirebaseKitErrorTests.swift
│   │   ├── FirebaseKitConfigurationTests.swift
│   │   ├── FirebaseKitDefaultStringsTests.swift
│   │   └── FirebaseKitContainerTests.swift
│   ├── FirebaseKitAuthTests/
│   │   └── FirebaseKitAuthTests.swift
│   ├── FirebaseKitRemoteConfigTests/
│   │   └── RemoteConfigKeyTests.swift
│   ├── FirebaseKitMessagingTests/
│   │   └── FirebaseKitMessagingTests.swift
│   ├── FirebaseKitFirestoreTests/
│   │   └── FirebaseKitFirestoreTests.swift
│   ├── FirebaseKitStorageTests/
│   │   └── StoragePathTests.swift
│   ├── FirebaseKitRealtimeDatabaseTests/
│   │   └── RealtimeDBPathTests.swift
│   └── FirebaseKitAnalyticsTests/
│       └── AnalyticsValueTests.swift
└── Examples/
    └── SwiftUIExample/
        └── ExampleApp.swift
```

## Testing

Core tests (error mapping, configuration, string provider, container, value conversions) run without a Firebase backend:

```bash
swift test --filter FirebaseKitCoreTests
swift test --filter FirebaseKitStorageTests
swift test --filter FirebaseKitRealtimeDatabaseTests
swift test --filter FirebaseKitAnalyticsTests
```

Auth, RemoteConfig, Messaging, Firestore, Storage, RealtimeDatabase, and Analytics integration tests are scaffolded for testing with Firebase emulators. See the test files for setup instructions.

## License

Apache License 2.0. See [LICENSE](LICENSE) for details.
