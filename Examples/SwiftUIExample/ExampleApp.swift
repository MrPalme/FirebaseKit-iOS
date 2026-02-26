//
//  ExampleApp.swift
//  FirebaseKit
//
//  Created by Markus Mock on 22.02.26.
//

import SwiftUI
import FirebaseCore
import FirebaseKitCore
import FirebaseKitAuth
import FirebaseKitRemoteConfig
import FirebaseKitMessaging
import FirebaseKitFirestore
import FirebaseKitStorage
import FirebaseKitRealtimeDatabase
import FirebaseKitAnalytics

// MARK: - App Entry Point

@main
struct ExampleApp: App {

    // Use UIApplicationDelegateAdaptor for APNs hooks
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    init() {
        // 1. Configure Firebase (host app responsibility)
        FirebaseApp.configure()

        // 2. Configure FirebaseKit
        do {
            try FirebaseKit.configure(
                FirebaseKitConfiguration(
                    environment: .debug,
                    modules: .all,
                    stringProvider: AppStringsProvider(),
                    logger: FirebaseKitConsoleLogger(minimumLevel: .debug)
                )
            )
        } catch {
            fatalError("FirebaseKit configuration failed: \(error)")
        }

        // 3. Register modules
        FirebaseKitAuthService.register()
        FirebaseKitRemoteConfigService.register(defaults: [
            "onboarding_enabled": true as NSObject,
            "max_upload_size_mb": 10 as NSObject,
        ])
        FirebaseKitMessagingService.register()
        FirebaseKitFirestoreService.register()
        FirebaseKitStorageService.register()
        FirebaseKitRealtimeDatabaseService.register()
        FirebaseKitAnalyticsService.register()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}

// MARK: - AppDelegate (APNs + Messaging Hooks)

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

// MARK: - Custom String Provider (Override Example)

struct AppStringsProvider: FirebaseKitStringProviding {
    func string(_ key: FirebaseKitStringKey) -> String {
        // Override specific keys; fall back to defaults for the rest.
        switch key {
        case .authInvalidCredentials:
            return "Oops! Wrong email or password. Please try again."
        default:
            return FirebaseKitDefaultStrings().string(key)
        }
    }
}

// MARK: - Host-App Analytics Definitions

/// Host-app-defined screens. FirebaseKit just logs them.
enum AppScreen: String, AnalyticsScreen {
    case login
    case home
    case settings
    case storage
    case realtimeDB

    var screenName: String { rawValue }
}

/// Host-app-defined events. FirebaseKit just processes them.
enum AppEvent: AnalyticsEvent {
    case buttonTapped(name: String, screen: String)
    case fileUploaded(path: String, sizeBytes: Int)
    case dbValueWritten(path: String)

    var name: String {
        switch self {
        case .buttonTapped: return "button_tapped"
        case .fileUploaded: return "file_uploaded"
        case .dbValueWritten: return "db_value_written"
        }
    }

    var parameters: [String: AnalyticsValue] {
        switch self {
        case .buttonTapped(let name, let screen):
            return [
                "button_name": .string(name),
                "screen": .string(screen),
            ]
        case .fileUploaded(let path, let sizeBytes):
            return [
                "path": .string(path),
                "size_bytes": .int(sizeBytes),
            ]
        case .dbValueWritten(let path):
            return ["path": .string(path)]
        }
    }
}

// MARK: - Root View

struct RootView: View {
    @StateObject private var authObserver = AuthSessionObserver(
        service: FirebaseKit.auth
    )

    var body: some View {
        Group {
            switch authObserver.session.state {
            case .signedOut:
                LoginView()
            case .signedIn:
                HomeView(user: authObserver.session.user!)
            }
        }
    }
}

// MARK: - Login View + ViewModel

struct LoginView: View {
    @StateObject private var viewModel = LoginViewModel()

    var body: some View {
        VStack(spacing: 16) {
            TextField("Email", text: $viewModel.email)
                .textContentType(.emailAddress)
                .autocapitalization(.none)

            SecureField("Password", text: $viewModel.password)
                .textContentType(.password)

            if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
            }

            Button("Sign In") {
                Task { await viewModel.signIn() }
            }
            .disabled(viewModel.isLoading)
            // Track taps on the sign-in button
            .trackTap(AppEvent.buttonTapped(name: "sign_in", screen: "login"))
        }
        .padding()
        // Track screen views
        .trackScreen(AppScreen.login)
    }
}

@MainActor
final class LoginViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var isLoading = false
    @Published var errorMessage: String?

    func signIn() async {
        isLoading = true
        errorMessage = nil

        do {
            try await FirebaseKit.auth.signIn(email: email, password: password)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}

// MARK: - Home View (Remote Config + Firestore + Storage + RealtimeDB + Analytics)

struct HomeView: View {
    let user: FirebaseAuthUser
    @StateObject private var viewModel = HomeViewModel()

    var body: some View {
        NavigationView {
            List {
                Section("Profile") {
                    Text("UID: \(user.uid)")
                    Text("Email: \(user.email ?? "—")")
                    Text("Name: \(user.displayName ?? "—")")
                }

                Section("Remote Config") {
                    Text("Onboarding: \(viewModel.onboardingEnabled ? "ON" : "OFF")")
                    Text("Max Upload: \(viewModel.maxUploadSizeMB) MB")
                }

                Section("Firestore Notes") {
                    ForEach(viewModel.notes, id: \.id) { note in
                        Text(note.title)
                    }
                }

                // Storage Example
                Section("Storage") {
                    Button("Upload Sample Image") {
                        Task { await viewModel.uploadSampleImage(userUID: user.uid) }
                    }
                    .trackTap(AppEvent.buttonTapped(name: "upload_image", screen: "home"))

                    if let downloadURL = viewModel.lastDownloadURL {
                        Text("URL: \(downloadURL.absoluteString.prefix(50))…")
                            .font(.caption)
                    }

                    Button("Download Sample Image") {
                        Task { await viewModel.downloadSampleImage(userUID: user.uid) }
                    }

                    if let downloadedSize = viewModel.downloadedImageSize {
                        Text("Downloaded: \(downloadedSize) bytes")
                            .font(.caption)
                    }
                }

                // Realtime Database Example
                Section("Realtime Database") {
                    Text("Status: \(viewModel.userStatus ?? "—")")

                    Button("Set Online") {
                        Task { await viewModel.setOnlineStatus(userUID: user.uid, online: true) }
                    }

                    Button("Set Offline") {
                        Task { await viewModel.setOnlineStatus(userUID: user.uid, online: false) }
                    }
                }

                // Direct Analytics Call Example
                Section("Analytics") {
                    Button("Log Custom Event") {
                        FirebaseKit.analytics.log(
                            event: AppEvent.buttonTapped(name: "custom_event", screen: "home")
                        )
                    }
                }
            }
            .navigationTitle("Home")
            .toolbar {
                Button("Sign Out") {
                    try? FirebaseKit.auth.signOut()
                }
                .trackTap(AppEvent.buttonTapped(name: "sign_out", screen: "home"))
            }
            .task {
                await viewModel.load(userUID: user.uid)
            }
        }
        // Track screen + set analytics context
        .trackScreen(AppScreen.home)
        .analyticsContext(screen: AppScreen.home)
    }
}

// MARK: - Home ViewModel (RemoteConfig + Firestore + Storage + RealtimeDB)

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var onboardingEnabled = false
    @Published var maxUploadSizeMB = 0
    @Published var notes: [Note] = []
    @Published var lastDownloadURL: URL?
    @Published var downloadedImageSize: Int?
    @Published var userStatus: String?

    // Typed Remote Config keys
    private let onboardingKey = RemoteConfigKey<Bool>("onboarding_enabled", default: false)
    private let maxUploadKey = RemoteConfigKey<Int>("max_upload_size_mb", default: 10)

    // Typed Realtime Database path
    private var statusObserveTask: Task<Void, Never>?

    func load(userUID: String) async {
        // Fetch Remote Config
        do {
            try await FirebaseKit.remoteConfig.fetchAndActivate()
            onboardingEnabled = try FirebaseKit.remoteConfig.value(for: onboardingKey)
            maxUploadSizeMB = try FirebaseKit.remoteConfig.value(for: maxUploadKey)
        } catch {
            print("RemoteConfig error: \(error)")
        }

        // Query Firestore with host-app decode closure
        do {
            notes = try await FirebaseKit.firestore.query(
                collectionPath: "users/\(userUID)/notes",
                build: { $0.order(by: "createdAt", descending: true).limit(to: 20) },
                decode: { snapshot in
                    Note(
                        id: snapshot.documentID,
                        title: snapshot.data?["title"] as? String ?? "Untitled",
                        body: snapshot.data?["body"] as? String ?? ""
                    )
                }
            )
        } catch {
            print("Firestore error: \(error)")
        }

        // Observe Realtime Database for status changes
        let statusPath = RealtimeDBPath<String>("users/\(userUID)/status")
        statusObserveTask?.cancel()
        statusObserveTask = Task {
            for await status in FirebaseKit.realtimeDatabase.observe(path: statusPath) {
                guard !Task.isCancelled else { break }
                self.userStatus = status ?? "unknown"
            }
        }
    }

    // MARK: - Storage Examples

    func uploadSampleImage(userUID: String) async {
        let sampleData = Data("Hello, Storage!".utf8)
        let path = StoragePath("users/\(userUID)/sample.txt")

        do {
            let metadata = try await FirebaseKit.storage.upload(
                data: sampleData,
                to: path,
                contentType: "text/plain"
            )
            print("Uploaded: \(metadata.size) bytes")

            // Get the download URL
            let url = try await FirebaseKit.storage.downloadURL(for: path)
            lastDownloadURL = url

            // Log analytics event
            FirebaseKit.analytics.log(
                event: AppEvent.fileUploaded(path: path.path, sizeBytes: sampleData.count)
            )
        } catch {
            print("Storage upload error: \(error)")
        }
    }

    func downloadSampleImage(userUID: String) async {
        let path = StoragePath("users/\(userUID)/sample.txt")

        do {
            let data = try await FirebaseKit.storage.download(from: path)
            downloadedImageSize = data.count
        } catch {
            print("Storage download error: \(error)")
        }
    }

    // MARK: - Realtime Database Examples

    func setOnlineStatus(userUID: String, online: Bool) async {
        do {
            try await FirebaseKit.realtimeDatabase.set(
                path: "users/\(userUID)/status",
                value: online ? "online" : "offline"
            )
            FirebaseKit.analytics.log(
                event: AppEvent.dbValueWritten(path: "users/\(userUID)/status")
            )
        } catch {
            print("RealtimeDB error: \(error)")
        }
    }
}

// MARK: - Note Model (Host-App Owned)

struct Note: Identifiable {
    let id: String
    let title: String
    let body: String
}

// MARK: - Writing a Firestore Document Example

/// Demonstrates writing a document with a host-app-provided encode closure.
func saveNoteExample(userUID: String, note: Note) async throws {
    try await FirebaseKit.firestore.setDocument(
        path: "users/\(userUID)/notes/\(note.id)",
        value: note,
        encode: { note in
            [
                "title": note.title,
                "body": note.body,
                "createdAt": Date().timeIntervalSince1970,
            ]
        }
    )
}

// MARK: - Messaging Token Observation Example

/// Demonstrates observing FCM token updates.
func observeFCMToken() async {
    for await token in FirebaseKit.messaging.fcmTokenStream {
        if let token {
            print("New FCM token: \(token)")
            // Send to your backend
        }
    }
}

// MARK: - Storage Upload with Progress Example

/// Demonstrates uploading data with progress tracking.
func uploadWithProgressExample(userUID: String) async {
    let data = Data(repeating: 0, count: 1_000_000) // 1 MB
    let path = StoragePath("users/\(userUID)/large_file.bin")

    for await progress in FirebaseKit.storage.uploadWithProgress(data: data, to: path) {
        print("Upload progress: \(Int(progress.fractionCompleted * 100))%")
    }
    print("Upload complete!")
}

// MARK: - Realtime Database Typed Path Example

/// Demonstrates reading a typed value using RealtimeDBPath.
func readUserProfileExample(userUID: String) async throws {
    struct UserProfile: Decodable {
        let name: String
        let age: Int
    }

    let profilePath = RealtimeDBPath<UserProfile>("users/\(userUID)/profile")
    if let profile = try await FirebaseKit.realtimeDatabase.get(path: profilePath) {
        print("User: \(profile.name), Age: \(profile.age)")
    }
}
