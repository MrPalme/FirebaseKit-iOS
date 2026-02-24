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
        }
        .padding()
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

// MARK: - Home View (Remote Config + Firestore Example)

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
            }
            .navigationTitle("Home")
            .toolbar {
                Button("Sign Out") {
                    try? FirebaseKit.auth.signOut()
                }
            }
            .task {
                await viewModel.load(userUID: user.uid)
            }
        }
    }
}

// MARK: - Home ViewModel (RemoteConfig + Firestore)

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var onboardingEnabled = false
    @Published var maxUploadSizeMB = 0
    @Published var notes: [Note] = []

    // Typed Remote Config keys
    private let onboardingKey = RemoteConfigKey<Bool>("onboarding_enabled", default: false)
    private let maxUploadKey = RemoteConfigKey<Int>("max_upload_size_mb", default: 10)

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
