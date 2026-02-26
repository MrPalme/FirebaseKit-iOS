//
//  AnalyticsUIKitExtensions.swift
//  FirebaseKit
//
//  Created by Markus Mock on 22.02.26.
//

#if canImport(UIKit)
import UIKit
import FirebaseKitCore

// MARK: - UIViewController Screen Tracking

public extension UIViewController {

    /// Logs a `screen_view` event for this view controller.
    ///
    /// Call this in `viewDidAppear(_:)` to track screen views in UIKit apps.
    ///
    /// ```swift
    /// override func viewDidAppear(_ animated: Bool) {
    ///     super.viewDidAppear(animated)
    ///     trackScreen(AppScreen.profile)
    /// }
    /// ```
    func trackScreen(_ screen: some AnalyticsScreen) {
        FirebaseKit.analytics.screen(screen)
    }
}

// MARK: - UIControl Tap Tracking

public extension UIControl {

    /// Logs an analytics event when the specified control event fires.
    ///
    /// ```swift
    /// upgradeButton.trackTap(AppEvent.buttonTapped(name: "upgrade", screen: "home"))
    /// ```
    ///
    /// - Parameters:
    ///   - event: The ``AnalyticsEvent`` to log.
    ///   - controlEvent: The `UIControl.Event` to observe. Defaults to `.touchUpInside`.
    func trackTap(_ event: some AnalyticsEvent, for controlEvent: UIControl.Event = .touchUpInside) {
        let action = AnalyticsTapAction(event: event)
        // Store the action to prevent deallocation
        objc_setAssociatedObject(self, &AnalyticsTapAction.associatedKey, action, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        addTarget(action, action: #selector(AnalyticsTapAction.handleTap), for: controlEvent)
    }
}

// MARK: - Internal Action Target

private final class AnalyticsTapAction: NSObject {
    static var associatedKey: UInt8 = 0

    private let logEvent: () -> Void

    init(event: some AnalyticsEvent) {
        self.logEvent = { FirebaseKit.analytics.log(event: event) }
        super.init()
    }

    @objc func handleTap() {
        logEvent()
    }
}
#endif
