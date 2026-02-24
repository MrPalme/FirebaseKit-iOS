# FirebaseKit-iOS

A modular, app-agnostic Firebase abstraction layer for iOS (Swift 5.9+). Designed for SwiftUI-first apps but fully usable from UIKit.
FirebaseKit handles initialization, typed access, consistent error mapping, and reusable integration logic. Host apps handle UI, configuration values, model mapping, and app-specific interpretation.

## Modules

- **FirebaseKitCore** — Foundation-only contracts, shared types, error types, logging, string provider, and dependency container. No Firebase SDK dependency.
- **FirebaseKitAuth** — FirebaseAuth wrapper behind protocols. Exposes session state via `AsyncStream` and `@MainActor ObservableObject`.
- **FirebaseKitRemoteConfig** — Remote Config wrapper with typed keys (`RemoteConfigKey<T>`) and automatic decoding for Bool, Int, Double, String, URL, and Decodable JSON.
- **FirebaseKitMessaging** — FCM wrapper with token handling, APNs bridging hooks, and topic subscription.
- **FirebaseKitFirestore** — Firestore CRUD wrappers with model mapping fully delegated to the host app via encode/decode closures.
- **FirebaseKitStorage** — Placeholder (scaffolded, not yet implemented).
- **FirebaseKitAnalytics** — Placeholder (scaffolded, not yet implemented).

## Requirements

- iOS 16+ / macOS 13+
- Swift 5.9+
- Firebase iOS SDK 11.0+

## Installation

Add FirebaseKit-iOS to your project via Swift Package Manager:

```swift
// In your Package.swift or Xcode project:
.package(url: "https://github.com/MrPalme/FirebaseKit-iOS.git", from: "1.0.0")
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
        modules: [.auth, .remoteConfig]  // Only auth + remote config
    )
)

FirebaseKitAuthService.register()
FirebaseKitRemoteConfigService.register()
// Messaging and Firestore are not registered — accessing them will fatalError with a clear message.
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

## Architecture

```
Host App
  │
  ├── FirebaseKitCore (protocols, types, errors, DI container)
  │     ├── FirebaseKitAuthServing (protocol)
  │     ├── FirebaseKitRemoteConfigServing (protocol)
  │     ├── FirebaseKitMessagingServing (protocol)
  │     └── FirebaseKitFirestoreServing (protocol)
  │
  ├── FirebaseKitAuth (concrete Firebase Auth implementation)
  ├── FirebaseKitRemoteConfig (concrete Remote Config implementation)
  ├── FirebaseKitMessaging (concrete FCM implementation)
  └── FirebaseKitFirestore (concrete Firestore implementation)
```

- Protocols live in `FirebaseKitCore` (no Firebase SDK dependency).
- Concrete implementations live in feature modules (depend on Firebase SDK).
- The `FirebaseKit` enum in Core is the single facade entry point.
- `FirebaseKitContainer` holds registered service instances.
- Host apps interact only with protocols and the facade.

## Threading

- UI-facing state updates (`AuthSessionObserver`, etc.) are `@MainActor`.
- Service calls (`signIn`, `fetchAndActivate`, `getDocument`, etc.) are `async` and can run off-main.
- All service classes are `Sendable`-safe with internal locking.

## Project Structure

```
FirebaseKit-iOS/
├── Package.swift
├── LICENSE
├── README.md
├── Sources/
│   ├── FirebaseKitCore/
│   │   ├── FirebaseKit.swift                  (facade)
│   │   ├── FirebaseKitConfiguration.swift
│   │   ├── FirebaseKitContainer.swift         (DI container)
│   │   ├── FirebaseKitEnvironment.swift
│   │   ├── FirebaseKitError.swift
│   │   ├── FirebaseKitLogging.swift
│   │   ├── FirebaseKitStringProviding.swift
│   │   ├── LogHelper.swift
│   │   └── Protocols/
│   │       ├── FirebaseKitAuthServing.swift
│   │       ├── FirebaseKitRemoteConfigServing.swift
│   │       ├── FirebaseKitMessagingServing.swift
│   │       └── FirebaseKitFirestoreServing.swift
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
│   │   └── FirebaseKitStorage.swift           (placeholder)
│   └── FirebaseKitAnalytics/
│       └── FirebaseKitAnalytics.swift         (placeholder)
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
│   └── FirebaseKitFirestoreTests/
│       └── FirebaseKitFirestoreTests.swift
└── Examples/
    └── SwiftUIExample/
        └── ExampleApp.swift
```

## Testing

Core tests (error mapping, configuration, string provider, container) run without a Firebase backend:

```bash
swift test --filter FirebaseKitCoreTests
```

Auth, RemoteConfig, Messaging, and Firestore tests are scaffolded for integration testing with Firebase emulators. See the test files for setup instructions.

## License

Apache License 2.0. See [LICENSE](LICENSE) for details.
