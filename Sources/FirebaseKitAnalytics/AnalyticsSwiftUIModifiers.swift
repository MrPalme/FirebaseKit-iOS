//
//  AnalyticsSwiftUIModifiers.swift
//  FirebaseKit
//
//  Created by Markus Mock on 22.02.26.
//

#if canImport(SwiftUI)
import SwiftUI
import FirebaseKitCore

// MARK: - Environment Key for Analytics Context

private struct AnalyticsScreenKey: EnvironmentKey {
    static let defaultValue: (any AnalyticsScreen)? = nil
}

public extension EnvironmentValues {
    /// The current analytics screen context, set via `.analyticsContext(screen:)`.
    var analyticsScreen: (any AnalyticsScreen)? {
        get { self[AnalyticsScreenKey.self] }
        set { self[AnalyticsScreenKey.self] = newValue }
    }
}

// MARK: - Screen Tracking Modifier

private struct TrackScreenModifier<S: AnalyticsScreen>: ViewModifier {
    let screen: S
    let deduplicate: Bool

    @State private var hasAppeared = false

    func body(content: Content) -> some View {
        content
            .onAppear {
                if deduplicate && hasAppeared { return }
                hasAppeared = true
                FirebaseKit.analytics.screen(screen)
            }
    }
}

// MARK: - Tap Tracking Modifier

private struct TrackTapModifier<E: AnalyticsEvent>: ViewModifier {
    let event: E

    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                TapGesture().onEnded {
                    FirebaseKit.analytics.log(event: event)
                }
            )
    }
}

// MARK: - Analytics Context Modifier

private struct AnalyticsContextModifier<S: AnalyticsScreen>: ViewModifier {
    let screen: S

    func body(content: Content) -> some View {
        content.environment(\.analyticsScreen, screen)
    }
}

// MARK: - View Extensions

public extension View {

    /// Logs a `screen_view` event when this view appears.
    ///
    /// - Parameters:
    ///   - screen: The ``AnalyticsScreen`` to log.
    ///   - deduplicate: If `true`, only the first `onAppear` fires the event.
    ///     Defaults to `true`. Set to `false` if you want every appearance logged.
    ///
    /// - Note: SwiftUI's `onAppear` may fire more than once (e.g. during
    ///   navigation transitions). Enable `deduplicate` to avoid double-counting.
    ///
    /// ```swift
    /// HomeView()
    ///     .trackScreen(AppScreen.home)
    /// ```
    func trackScreen(_ screen: some AnalyticsScreen, deduplicate: Bool = true) -> some View {
        modifier(TrackScreenModifier(screen: screen, deduplicate: deduplicate))
    }

    /// Logs an analytics event when this view is tapped.
    ///
    /// Uses `simultaneousGesture` so it does not interfere with existing
    /// tap handlers (buttons, navigation links, etc.).
    ///
    /// ```swift
    /// Button("Upgrade") { ... }
    ///     .trackTap(AppEvent.buttonTapped(name: "upgrade", screen: "settings"))
    /// ```
    func trackTap(_ event: some AnalyticsEvent) -> some View {
        modifier(TrackTapModifier(event: event))
    }

    /// Sets the analytics screen context in the SwiftUI environment.
    ///
    /// Child views can read `@Environment(\.analyticsScreen)` to attach
    /// contextual screen information to tap events.
    ///
    /// ```swift
    /// NavigationView {
    ///     SettingsView()
    ///         .analyticsContext(screen: AppScreen.settings)
    /// }
    /// ```
    func analyticsContext(screen: some AnalyticsScreen) -> some View {
        modifier(AnalyticsContextModifier(screen: screen))
    }
}
#endif
