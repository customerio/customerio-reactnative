// This byte-vendored fixture keeps its UIKit evidence adapters in one reviewable type and file.
// swiftlint:disable file_length

import Foundation
import UIKit
import UserNotifications

public enum LifecycleTraceRoutingResult: String {
    case handled
    case unhandled
    case redirect
    case success
    case failure
    case newData = "new-data"
    case noData = "no-data"
    case none
    case unknown
}

public enum LifecycleTraceErrorClass: String {
    case registration
    case configuration
    case routing
    case other
    case none
}

public enum LifecycleTraceDelegatePeer: String {
    case host
    case customerIOMessagingPush = "customerio-messaging-push"
    case expoNotifications = "expo-notifications"
    case flutterLocalNotifications = "flutter-local-notifications"
    case reactNativePushNotification = "react-native-push-notification"
    case frameworkOther = "framework-other"
    case unknown
    case none
}

// The adapters stay grouped so every emitted safe fact remains auditable in one namespace.
// swiftlint:disable type_body_length
public enum LifecycleTraceEvidence {
    public static func isCustomerIOLiveActivityRoute(_ url: URL) -> Bool {
        url.scheme == "cio-live-activity"
            && url.host == "open"
            && URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems != nil
    }

    /// Returns false when a Customer.io Live Activity route has no usable delivery/redirect fact,
    /// or when its redirect cannot be parsed by the SDK.
    /// The host must still execute the production route, but the fixture cannot claim a coherent
    /// Customer.io redirect result for that malformed stimulus.
    public static func isTraceableURLRoute(_ url: URL) -> Bool {
        guard isCustomerIOLiveActivityRoute(url),
              let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems else {
            return true
        }
        let deliveryID = items.first(where: { $0.name == "cio_delivery_id" })?.value
        let redirect = items.first(where: { $0.name == "cio_redirect" })?.value
        guard deliveryID?.isEmpty == false || redirect?.isEmpty == false else { return false }
        guard let redirect, !redirect.isEmpty else { return true }
        return URL(string: redirect) != nil
    }

    public static func observe(applicationState: UIApplication.State) -> LifecycleTraceObservation {
        let value: String
        switch applicationState {
        case .active:
            value = "active"
        case .inactive:
            value = "inactive"
        case .background:
            value = "background"
        @unknown default:
            value = "unknown"
        }
        return LifecycleTraceObservation(enums: [.appState: value])
    }

    @MainActor
    public static func observe(scene: UIScene) -> LifecycleTraceObservation {
        LifecycleTraceObservation(
            flags: [.hasScene: true],
            enums: [
                .appState: appState(scene.activationState),
                .sceneRole: sceneRole(scene.session.role),
                .sceneState: sceneState(scene.activationState)
            ],
            correlations: [.scene: .string(scene.session.persistentIdentifier)]
        )
    }

    @MainActor
    public static func observe(scene: UIScene, callback: LifecycleTraceCallback) -> LifecycleTraceObservation {
        var observation = observe(scene: scene)
        let state: String
        switch callback {
        case .sceneWillConnect:
            state = "pre-application"
        case .sceneDidDisconnect:
            state = scene.activationState == .background ? "background" : "inactive"
        case .sceneDidBecomeActive:
            state = "active"
        case .sceneWillResignActive:
            state = scene.activationState == .foregroundActive ? "active" : "inactive"
        case .sceneDidEnterBackground:
            state = "background"
        case .sceneWillEnterForeground:
            state = scene.activationState == .background ? "background" : "inactive"
        default:
            return observation
        }
        observation.enums[.appState] = state
        return observation
    }

    @MainActor
    public static func observe(sceneSession: UISceneSession) -> LifecycleTraceObservation {
        LifecycleTraceObservation(
            flags: [.hasScene: true],
            enums: [.sceneRole: sceneRole(sceneSession.role), .sceneState: "unattached"],
            correlations: [.scene: .string(sceneSession.persistentIdentifier)]
        )
    }

    public static func observe(sceneSessions: Set<UISceneSession>) -> LifecycleTraceObservation {
        LifecycleTraceObservation(counts: [.discardedScenes: sceneSessions.count])
    }

    public static func observe(connectedScenes: Set<UIScene>) -> LifecycleTraceObservation {
        LifecycleTraceObservation(counts: [.connectedScenes: connectedScenes.count])
    }

    public static func observe(launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> LifecycleTraceObservation {
        LifecycleTraceObservation(
            flags: [.hasLaunchOptions: launchOptions != nil],
            counts: [.launchOptionKeys: launchOptions?.count ?? 0]
        )
    }

    public static func observe(url: URL?) -> LifecycleTraceObservation {
        guard let url else {
            return LifecycleTraceObservation(
                flags: [.hasURL: false],
                counts: [.urlPathComponents: 0, .urlQueryItems: 0],
                enums: [.urlScheme: "none", .urlClass: "none"]
            )
        }
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let scheme = url.scheme?.lowercased()
        let queryItems = components?.queryItems ?? []
        let deliveryID = queryItems.first { $0.name == "cio_delivery_id" }?.value
        let hasDeliveryToken = queryItems.contains { $0.name == "cio_delivery_token" && $0.value != nil }
        let hasRedirect = queryItems.contains { $0.name == "cio_redirect" && $0.value != nil }
        var correlations: [LifecycleTraceAliasNamespace: LifecycleTraceCorrelationValue] = [
            .url: .string(url.absoluteString)
        ]
        if let deliveryID {
            correlations[.delivery] = .string(deliveryID)
        }
        return LifecycleTraceObservation(
            flags: [
                .hasURL: true,
                .hasDeliveryID: deliveryID != nil,
                .hasDeliveryToken: hasDeliveryToken,
                .hasRedirect: hasRedirect
            ],
            counts: [
                .urlPathComponents: url.pathComponents.filter { $0 != "/" }.count,
                .urlQueryItems: queryItems.count
            ],
            enums: [
                .urlScheme: urlScheme(scheme),
                .urlClass: urlClass(scheme)
            ],
            correlations: correlations
        )
    }

    @MainActor
    public static func observe(urlContexts: Set<UIOpenURLContext>) -> LifecycleTraceObservation {
        let base = LifecycleTraceObservation(
            flags: [.hasURL: !urlContexts.isEmpty],
            counts: [.urlContexts: urlContexts.count]
        )
        guard let first = urlContexts.first else {
            return base.merging(observe(url: nil))
        }
        return base.merging(observe(url: first.url))
    }

    public static func observe(userActivity: NSUserActivity?) -> LifecycleTraceObservation {
        guard let userActivity else {
            return LifecycleTraceObservation(
                flags: [.hasUserActivity: false],
                counts: [.userActivities: 0],
                enums: [.activityClass: "none"]
            )
        }
        let activityClass = userActivity.activityType == NSUserActivityTypeBrowsingWeb ? "web-browsing" : "custom"
        let base = LifecycleTraceObservation(
            flags: [.hasUserActivity: true],
            counts: [.userActivities: 1],
            enums: [.activityClass: activityClass]
        )
        guard let url = userActivity.webpageURL else { return base }
        return base.merging(observe(url: url))
    }

    @MainActor
    public static func observe(connectionOptions: UIScene.ConnectionOptions) -> LifecycleTraceObservation {
        var observation = LifecycleTraceObservation(
            flags: [
                .hasURL: !connectionOptions.urlContexts.isEmpty,
                .hasUserActivity: !connectionOptions.userActivities.isEmpty,
                .hasShortcut: connectionOptions.shortcutItem != nil,
                .hasNotification: connectionOptions.notificationResponse != nil,
                .hasNotificationResponse: connectionOptions.notificationResponse != nil
            ],
            counts: [
                .urlContexts: connectionOptions.urlContexts.count,
                .userActivities: connectionOptions.userActivities.count
            ]
        )
        if let url = connectionOptions.urlContexts.first?.url {
            observation = observation.merging(observe(url: url))
        }
        if let activity = connectionOptions.userActivities.first {
            observation = observation.merging(observe(userActivity: activity))
        }
        if let shortcut = connectionOptions.shortcutItem {
            observation = observation.merging(observe(shortcutItem: shortcut))
        }
        if let response = connectionOptions.notificationResponse {
            observation = observation.merging(observe(notificationResponse: response, delegatePeer: .customerIOMessagingPush))
        }
        return observation
    }

    public static func observe(shortcutItem: UIApplicationShortcutItem?) -> LifecycleTraceObservation {
        LifecycleTraceObservation(
            flags: [.hasShortcut: shortcutItem != nil],
            enums: [.actionClass: shortcutItem == nil ? "none" : "custom"]
        )
    }

    public static func observe(deviceToken: Data) -> LifecycleTraceObservation {
        LifecycleTraceObservation(
            flags: [.hasDeviceToken: !deviceToken.isEmpty],
            counts: [.deviceTokenBytes: deviceToken.count],
            correlations: [.request: .data(deviceToken)]
        )
    }

    public static func observe(fcmToken: String?) -> LifecycleTraceObservation {
        let token = fcmToken ?? ""
        return LifecycleTraceObservation(
            flags: [.hasFCMToken: !token.isEmpty],
            counts: [.fcmTokenCharacters: token.count]
        )
    }

    public static func observe(errorClass: LifecycleTraceErrorClass) -> LifecycleTraceObservation {
        LifecycleTraceObservation(enums: [.errorClass: errorClass.rawValue])
    }

    public static func observe(routingResult: LifecycleTraceRoutingResult) -> LifecycleTraceObservation {
        LifecycleTraceObservation(
            flags: [.handled: routingResult == .handled || routingResult == .redirect || routingResult == .success],
            enums: [.result: routingResult.rawValue]
        )
    }

    public static func observe(delegatePeer: LifecycleTraceDelegatePeer) -> LifecycleTraceObservation {
        LifecycleTraceObservation(enums: [.delegatePeer: delegatePeer.rawValue])
    }

    public static func observe(notification: UNNotification, delegatePeer: LifecycleTraceDelegatePeer) -> LifecycleTraceObservation {
        observe(notificationRequest: notification.request, delegatePeer: delegatePeer)
    }

    public static func observe(
        notificationRequest: UNNotificationRequest,
        delegatePeer: LifecycleTraceDelegatePeer = .customerIOMessagingPush
    ) -> LifecycleTraceObservation {
        let userInfo = notificationRequest.content.userInfo
        let deliveryID = userInfo["CIO-Delivery-ID"] as? String
        let deliveryToken = userInfo["CIO-Delivery-Token"] as? String
        var correlations: [LifecycleTraceAliasNamespace: LifecycleTraceCorrelationValue] = [
            .request: .string(notificationRequest.identifier)
        ]
        if let deliveryID {
            correlations[.delivery] = .string(deliveryID)
        }
        return LifecycleTraceObservation(
            flags: [
                .hasNotification: true,
                .hasAPS: userInfo["aps"] != nil,
                .hasDeliveryID: deliveryID != nil,
                .hasDeliveryToken: deliveryToken != nil
            ],
            counts: [.notificationUserInfoKeys: userInfo.count],
            enums: [
                .notificationOrigin: notificationOrigin(notificationRequest.trigger),
                .notificationClass: deliveryID != nil && deliveryToken != nil ? "customerio" : "non-customerio",
                .delegatePeer: delegatePeer.rawValue
            ],
            correlations: correlations
        )
    }

    public static func observe(
        notificationResponse: UNNotificationResponse,
        delegatePeer: LifecycleTraceDelegatePeer = .customerIOMessagingPush
    ) -> LifecycleTraceObservation {
        observe(notificationRequest: notificationResponse.notification.request, delegatePeer: delegatePeer)
            .merging(LifecycleTraceObservation(
                flags: [.hasNotificationResponse: true],
                enums: [.actionClass: actionClass(notificationResponse.actionIdentifier)]
            ))
    }

    public static func observe(presentationOptions: UNNotificationPresentationOptions) -> LifecycleTraceObservation {
        let hasAlert = presentationOptions.contains(.alert)
        let hasBadge = presentationOptions.contains(.badge)
        let hasSound = presentationOptions.contains(.sound)
        var hasBanner = false
        var hasList = false
        if #available(iOS 14.0, *) {
            hasBanner = presentationOptions.contains(.banner)
            hasList = presentationOptions.contains(.list)
        }
        let count = [hasAlert, hasBadge, hasSound, hasBanner, hasList].filter { $0 }.count
        return LifecycleTraceObservation(
            flags: [
                .presentationAlert: hasAlert,
                .presentationBadge: hasBadge,
                .presentationSound: hasSound,
                .presentationBanner: hasBanner,
                .presentationList: hasList
            ],
            counts: [.presentationOptions: count],
            enums: [.presentationClass: count == 0 ? "suppressed" : "visible"]
        )
    }

    public static func observe(scenePhase: String) -> LifecycleTraceObservation {
        LifecycleTraceObservation(enums: [.appState: scenePhase])
    }

    private static func urlScheme(_ scheme: String?) -> String {
        switch scheme {
        case "https": return "https"
        case "http": return "http"
        case .some: return "custom"
        case .none: return "unknown"
        }
    }

    private static func urlClass(_ scheme: String?) -> String {
        switch scheme {
        case "cio-live-activity": return "cio-live-activity"
        case "https", "http": return "web"
        case .some: return "custom-scheme"
        case .none: return "other"
        }
    }

    private static func sceneRole(_ role: UISceneSession.Role) -> String {
        switch role {
        case .windowApplication: return "application"
        case .windowExternalDisplay: return "external-display"
        default: return "unknown"
        }
    }

    private static func sceneState(_ state: UIScene.ActivationState) -> String {
        switch state {
        case .unattached: return "unattached"
        case .foregroundActive: return "foreground-active"
        case .foregroundInactive: return "foreground-inactive"
        case .background: return "background"
        @unknown default: return "unknown"
        }
    }

    private static func appState(_ state: UIScene.ActivationState) -> String {
        switch state {
        case .unattached: return "pre-application"
        case .foregroundActive: return "active"
        case .foregroundInactive: return "inactive"
        case .background: return "background"
        @unknown default: return "unknown"
        }
    }

    private static func notificationOrigin(_ trigger: UNNotificationTrigger?) -> String {
        if trigger is UNPushNotificationTrigger { return "remote" }
        if trigger != nil { return "local" }
        return "unknown"
    }

    private static func actionClass(_ identifier: String) -> String {
        switch identifier {
        case UNNotificationDefaultActionIdentifier: return "default"
        case UNNotificationDismissActionIdentifier: return "dismiss"
        default: return "custom"
        }
    }
}

// swiftlint:enable type_body_length

/// Converts temporary source-patch notifications into the one process-wide Swift stream.
public final class LifecycleTracePlatformProbeObserver: @unchecked Sendable {
    private let lock = NSLock()
    private let center: NotificationCenter
    private var isActive = true
    private var latestRegistrationRequest: LifecycleTraceCorrelationValue?
    private var token: NSObjectProtocol?

    public init(center: NotificationCenter = .default) {
        self.center = center
        self.token = center.addObserver(
            forName: LifecycleTraceProbe.notificationName,
            object: center,
            queue: nil
        ) { [weak self] notification in
            self?.receive(notification)
        }
        LifecycleTraceHarness.registerEndCleanup { [weak self] in
            self?.stop()
        }
    }

    deinit {
        stop()
    }

    // The closed seat switch intentionally rejects every unrecognized probe notification.
    // swiftlint:disable:next function_body_length cyclomatic_complexity
    private func receive(_ notification: Notification) {
        lock.lock()
        let shouldReceive = isActive
        lock.unlock()
        guard shouldReceive,
              notification.object as AnyObject? === center,
              notification.userInfo?[LifecycleTraceProbe.processInstanceIDKey] as? String
              == LifecycleTraceHarness.sharedRecorder?.processInstanceID else { return }
        guard let seat = notification.userInfo?[LifecycleTraceProbe.seatKey] as? String else { return }
        switch seat {
        case "notification-center.will-present.entry":
            guard let value = notification.userInfo?[LifecycleTraceProbe.notificationKey] as? UNNotification else { return }
            LifecycleTraceProbe.post(
                callback: .notificationCenterWillPresent,
                owner: .notificationCenterDelegate,
                kind: .osCallback,
                phase: .entry,
                observations: LifecycleTraceEvidence.observe(notification: value, delegatePeer: .customerIOMessagingPush)
            )
        case "notification-center.did-receive-response.entry":
            guard let value = notification.userInfo?[LifecycleTraceProbe.notificationResponseKey] as? UNNotificationResponse else { return }
            LifecycleTraceProbe.post(
                callback: .notificationCenterDidReceiveResponse,
                owner: .notificationCenterDelegate,
                kind: .osCallback,
                phase: .entry,
                observations: LifecycleTraceEvidence.observe(notificationResponse: value, delegatePeer: .customerIOMessagingPush)
            )
        case "customerio.handle-notification-response.result":
            guard let value = notification.userInfo?[LifecycleTraceProbe.notificationResponseKey] as? UNNotificationResponse,
                  notification.userInfo?[LifecycleTraceProbe.handledKey] as? Bool == true else { return }
            LifecycleTraceProbe.post(
                callback: .customerIOHandleNotificationResponse,
                owner: .customerIOSDK,
                kind: .sdkRouting,
                phase: .result,
                observations: LifecycleTraceEvidence.observe(notificationResponse: value, delegatePeer: .customerIOMessagingPush),
                LifecycleTraceEvidence.observe(routingResult: .handled)
            )
        case "notification-center.did-receive-response.terminal":
            LifecycleTraceHarness.endScenario(after: .notificationResponse)
        case "application.did-register-for-remote-notifications.entry":
            guard let value = notification.userInfo?[LifecycleTraceProbe.deviceTokenKey] as? Data else { return }
            setLatestRegistrationRequest(.data(value))
            LifecycleTraceProbe.post(
                callback: .applicationDidRegisterForRemoteNotifications,
                owner: .applicationDelegate,
                kind: .osCallback,
                phase: .entry,
                observations: LifecycleTraceEvidence.observe(deviceToken: value)
            )
        case "application.did-fail-to-register-for-remote-notifications.entry":
            LifecycleTraceProbe.post(
                callback: .applicationDidFailToRegisterForRemoteNotifications,
                owner: .applicationDelegate,
                kind: .osCallback,
                phase: .entry,
                observations: LifecycleTraceEvidence.observe(errorClass: .registration),
                LifecycleTraceEvidence.observe(routingResult: .failure)
            )
        case "application.did-fail-to-register-for-remote-notifications.terminal":
            LifecycleTraceHarness.endScenario(after: .registrationFailure)
        case "fcm.registration-token-refreshed.entry":
            guard let value = notification.userInfo?[LifecycleTraceProbe.fcmTokenKey] as? String else { return }
            LifecycleTraceProbe.post(
                callback: .fcmRegistrationTokenRefreshed,
                owner: .fcmMessagingDelegate,
                kind: .frameworkCallback,
                phase: .entry,
                observations: LifecycleTraceEvidence.observe(fcmToken: value), requestCorrelation()
            )
        case "customerio.register-device-token.apn.result":
            guard let value = notification.userInfo?[LifecycleTraceProbe.deviceTokenKey] as? Data else { return }
            LifecycleTraceProbe.post(
                callback: .customerIORegisterDeviceToken,
                owner: .customerIOSDK,
                kind: .sdkRouting,
                phase: .result,
                observations: LifecycleTraceEvidence.observe(deviceToken: value),
                LifecycleTraceEvidence.observe(routingResult: .unknown)
            )
            LifecycleTraceHarness.endScenario(after: .tokenRegistration)
        case "customerio.register-device-token.fcm.result":
            guard let value = notification.userInfo?[LifecycleTraceProbe.fcmTokenKey] as? String else { return }
            LifecycleTraceProbe.post(
                callback: .customerIORegisterDeviceToken,
                owner: .customerIOSDK,
                kind: .sdkRouting,
                phase: .result,
                observations: LifecycleTraceEvidence.observe(fcmToken: value), requestCorrelation(),
                LifecycleTraceEvidence.observe(routingResult: .unknown)
            )
            LifecycleTraceHarness.endScenario(after: .tokenRegistration)
        default:
            return
        }
    }

    private func setLatestRegistrationRequest(_ value: LifecycleTraceCorrelationValue) {
        lock.lock()
        latestRegistrationRequest = value
        lock.unlock()
    }

    private func requestCorrelation() -> LifecycleTraceObservation {
        lock.lock()
        defer { lock.unlock() }
        guard let latestRegistrationRequest else { return LifecycleTraceObservation() }
        return LifecycleTraceObservation(correlations: [.request: latestRegistrationRequest])
    }

    private func stop() {
        lock.lock()
        guard isActive else {
            lock.unlock()
            return
        }
        isActive = false
        latestRegistrationRequest = nil
        let token = self.token
        self.token = nil
        lock.unlock()
        if let token {
            center.removeObserver(token)
        }
    }
}
