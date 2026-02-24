//
//  AuthSessionObserver.swift
//  FirebaseKit
//
//  Created by Markus Mock on 22.02.26.
//

import Foundation
import FirebaseKitCore

/// A `@MainActor` observable object that tracks the current auth session.
///
/// SwiftUI views can use this to reactively update when auth state changes.
///
/// ```swift
/// struct ContentView: View {
///     @StateObject private var authObserver = AuthSessionObserver(service: FirebaseKit.auth)
///
///     var body: some View {
///         switch authObserver.session.state {
///         case .signedIn:
///             HomeView()
///         case .signedOut:
///             LoginView()
///         }
///     }
/// }
/// ```
@MainActor
public final class AuthSessionObserver: ObservableObject {

    /// The current auth session.
    @Published public private(set) var session: FirebaseAuthSession

    private var streamTask: Task<Void, Never>?

    /// Creates an observer for the given auth service.
    ///
    /// - Parameter service: The auth service to observe.
    public init(service: any FirebaseKitAuthServing) {
        self.session = service.session

        streamTask = Task { [weak self] in
            for await newSession in service.sessionStream {
                guard !Task.isCancelled else { break }
                self?.session = newSession
            }
        }
    }

    deinit {
        streamTask?.cancel()
    }
}
