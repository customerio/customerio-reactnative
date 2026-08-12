// This byte-vendored fixture keeps the canonical closed vocabulary in one reviewable file.
// swiftlint:disable file_length

import Foundation

public enum LifecycleTraceIntegration: String, Codable, Sendable {
    case nativeIOS = "native-ios"
    case flutter
    case expo
    case reactNative = "react-native"
}

public enum LifecycleTraceRuntime: String, Codable, Sendable {
    case swift
    case dart
    case javascript
}

public enum LifecycleTraceProvider: String, Codable, Sendable {
    case apn
    case fcm
    case local
    case none
    case unknown
}

public enum LifecycleTraceScenario: String, Codable, Sendable {
    case unscoped
    case iconColdLaunch = "icon-cold-launch"
    case pushForeground = "push-foreground"
    case pushTapWarm = "push-tap-warm"
    case pushTapCold = "push-tap-cold"
    case localNotificationForeground = "local-notification-foreground"
    case localNotificationTapWarm = "local-notification-tap-warm"
    case localNotificationTapCold = "local-notification-tap-cold"
    case customURLWarm = "custom-url-warm"
    case customURLCold = "custom-url-cold"
    case universalLinkWarm = "universal-link-warm"
    case universalLinkCold = "universal-link-cold"
    case quickActionWarm = "quick-action-warm"
    case quickActionCold = "quick-action-cold"
    case liveActivityTapWarm = "live-activity-tap-warm"
    case liveActivityTapCold = "live-activity-tap-cold"
    case tokenRegistration = "token-registration"
    case registrationFailure = "registration-failure"
    case backgroundFetch = "background-fetch"
    case appBackgroundForeground = "app-background-foreground"
    case notificationSettings = "notification-settings"
    case unitFixture = "unit-fixture"

    public var isColdStart: Bool {
        switch self {
        case .iconColdLaunch, .pushTapCold, .localNotificationTapCold, .customURLCold,
             .universalLinkCold, .quickActionCold, .liveActivityTapCold:
            return true
        default:
            return false
        }
    }
}

public enum LifecycleTraceEvidenceLevel: String, Codable, Sendable {
    case diagnostic
    case l2 = "L2"
    case l3 = "L3"
}

public enum LifecycleTraceOwner: String, Codable, Sendable {
    case applicationDelegate = "application-delegate"
    case sceneDelegate = "scene-delegate"
    case swiftUIScene = "swiftui-scene"
    case notificationCenterDelegate = "notification-center-delegate"
    case uikitNotification = "uikit-notification"
    case rctNotification = "rct-notification"
    case flutterEngine = "flutter-engine"
    case flutterPlugin = "flutter-plugin"
    case flutterDart = "flutter-dart"
    case expoFramework = "expo-framework"
    case expoSubscriber = "expo-subscriber"
    case expoNotifications = "expo-notifications"
    case expoJavaScript = "expo-javascript"
    case reactNativeFramework = "react-native-framework"
    case reactNativeJavaScript = "react-native-javascript"
    case fcmMessagingDelegate = "fcm-messaging-delegate"
    case host
    case customerIOSDK = "customerio-sdk"
    case traceRecorder = "trace-recorder"
    case fixture
}

public enum LifecycleTraceKind: String, Codable, Sendable {
    case osCallback = "os-callback"
    case frameworkCallback = "framework-callback"
    case observerNotification = "observer-notification"
    case hostRouting = "host-routing"
    case sdkRouting = "sdk-routing"
    case appReceived = "app-received"
    case traceControl = "trace-control"
    case fixtureControl = "fixture-control"
    case completionFixture = "completion-fixture"
}

public enum LifecycleTracePhase: String, Codable, Sendable {
    case entry
    case intent
    case result
    case stateChange = "state-change"
    case completion
}

/// Existing terminal seats that may close a harness scenario after their trace record is queued.
public enum LifecycleTraceTerminal: Sendable {
    case activeScene
    case notificationResponse
    case hostURLRoute
    case hostUserActivityRoute
    case tokenRegistration
    case registrationFailure
}

/// Closed callback vocabulary copied from `ios27-lifecycle-trace-v1.schema.json`.
public enum LifecycleTraceCallback: String, Codable, CaseIterable, Sendable {
    case applicationDidFinishLaunching = "application.did-finish-launching"
    case applicationConfigurationForConnecting = "application.configuration-for-connecting"
    case applicationDidDiscardSceneSessions = "application.did-discard-scene-sessions"
    case applicationDidBecomeActive = "application.did-become-active"
    case applicationWillResignActive = "application.will-resign-active"
    case applicationDidEnterBackground = "application.did-enter-background"
    case applicationWillEnterForeground = "application.will-enter-foreground"
    case applicationWillTerminate = "application.will-terminate"
    case applicationOpenURL = "application.open-url"
    case applicationContinueUserActivity = "application.continue-user-activity"
    case applicationPerformQuickAction = "application.perform-quick-action"
    case applicationDidRegisterForRemoteNotifications = "application.did-register-for-remote-notifications"
    case applicationDidFailToRegisterForRemoteNotifications = "application.did-fail-to-register-for-remote-notifications"
    case applicationDidReceiveRemoteNotification = "application.did-receive-remote-notification"
    case applicationPerformBackgroundFetch = "application.perform-background-fetch"
    case sceneWillConnect = "scene.will-connect"
    case sceneDidDisconnect = "scene.did-disconnect"
    case sceneDidBecomeActive = "scene.did-become-active"
    case sceneWillResignActive = "scene.will-resign-active"
    case sceneDidEnterBackground = "scene.did-enter-background"
    case sceneWillEnterForeground = "scene.will-enter-foreground"
    case sceneOpenURLContexts = "scene.open-url-contexts"
    case sceneContinueUserActivity = "scene.continue-user-activity"
    case scenePerformQuickAction = "scene.perform-quick-action"
    case swiftUIOnOpenURL = "swiftui.on-open-url"
    case swiftUIScenePhaseChange = "swiftui.scene-phase-change"
    case notificationCenterWillPresent = "notification-center.will-present"
    case notificationCenterDidReceiveResponse = "notification-center.did-receive-response"
    case notificationCenterSettings = "notification-center.settings"
    case apnsDeviceTokenRegistered = "apns.device-token-registered"
    case apnsDeviceTokenRegistrationFailed = "apns.device-token-registration-failed"
    case fcmRegistrationTokenRefreshed = "fcm.registration-token-refreshed"
    case uikitApplicationDidFinishLaunchingNotification = "uikit.application-did-finish-launching-notification"
    case uikitApplicationDidBecomeActiveNotification = "uikit.application-did-become-active-notification"
    case uikitApplicationWillResignActiveNotification = "uikit.application-will-resign-active-notification"
    case uikitApplicationDidEnterBackgroundNotification = "uikit.application-did-enter-background-notification"
    case uikitApplicationWillEnterForegroundNotification = "uikit.application-will-enter-foreground-notification"
    case uikitApplicationWillTerminateNotification = "uikit.application-will-terminate-notification"
    case uikitSceneWillConnectNotification = "uikit.scene-will-connect-notification"
    case uikitSceneDidDisconnectNotification = "uikit.scene-did-disconnect-notification"
    case uikitSceneDidActivateNotification = "uikit.scene-did-activate-notification"
    case uikitSceneWillDeactivateNotification = "uikit.scene-will-deactivate-notification"
    case uikitSceneDidEnterBackgroundNotification = "uikit.scene-did-enter-background-notification"
    case uikitSceneWillEnterForegroundNotification = "uikit.scene-will-enter-foreground-notification"
    case rctJavaScriptWillStartLoadingNotification = "rct.javascript-will-start-loading-notification"
    case rctJavaScriptDidLoadNotification = "rct.javascript-did-load-notification"
    case rctJavaScriptDidFailToLoadNotification = "rct.javascript-did-fail-to-load-notification"
    case rctDidInitializeModuleNotification = "rct.did-initialize-module-notification"
    case rctBridgeWillReloadNotification = "rct.bridge-will-reload-notification"
    case rctBridgeDidInvalidateModulesNotification = "rct.bridge-did-invalidate-modules-notification"
    case rctInstanceDidLoadBundleNotification = "rct.instance-did-load-bundle-notification"
    case flutterImplicitEngineCreated = "flutter.implicit-engine-created"
    case flutterPluginRegistered = "flutter.plugin-registered"
    case flutterApplicationDidFinishLaunchingForwarded = "flutter.application.did-finish-launching-forwarded"
    case flutterApplicationDidBecomeActiveForwarded = "flutter.application.did-become-active-forwarded"
    case flutterApplicationWillResignActiveForwarded = "flutter.application.will-resign-active-forwarded"
    case flutterApplicationDidEnterBackgroundForwarded = "flutter.application.did-enter-background-forwarded"
    case flutterApplicationWillEnterForegroundForwarded = "flutter.application.will-enter-foreground-forwarded"
    case flutterApplicationWillTerminateForwarded = "flutter.application.will-terminate-forwarded"
    case flutterApplicationOpenURLForwarded = "flutter.application.open-url-forwarded"
    case flutterApplicationContinueUserActivityForwarded = "flutter.application.continue-user-activity-forwarded"
    case flutterApplicationPerformQuickActionForwarded = "flutter.application.perform-quick-action-forwarded"
    case flutterApplicationDidRegisterForRemoteNotificationsForwarded = "flutter.application.did-register-for-remote-notifications-forwarded"
    case flutterApplicationDidFailToRegisterForRemoteNotificationsForwarded = "flutter.application.did-fail-to-register-for-remote-notifications-forwarded"
    case flutterApplicationDidReceiveRemoteNotificationForwarded = "flutter.application.did-receive-remote-notification-forwarded"
    case flutterApplicationPerformBackgroundFetchForwarded = "flutter.application.perform-background-fetch-forwarded"
    case flutterSceneWillConnectForwarded = "flutter.scene.will-connect-forwarded"
    case flutterSceneDidDisconnectForwarded = "flutter.scene.did-disconnect-forwarded"
    case flutterSceneDidBecomeActiveForwarded = "flutter.scene.did-become-active-forwarded"
    case flutterSceneWillResignActiveForwarded = "flutter.scene.will-resign-active-forwarded"
    case flutterSceneDidEnterBackgroundForwarded = "flutter.scene.did-enter-background-forwarded"
    case flutterSceneWillEnterForegroundForwarded = "flutter.scene.will-enter-foreground-forwarded"
    case flutterSceneOpenURLContextsForwarded = "flutter.scene.open-url-contexts-forwarded"
    case flutterSceneContinueUserActivityForwarded = "flutter.scene.continue-user-activity-forwarded"
    case flutterScenePerformQuickActionForwarded = "flutter.scene.perform-quick-action-forwarded"
    case flutterNotificationCenterWillPresentForwarded = "flutter.notification-center.will-present-forwarded"
    case flutterNotificationCenterDidReceiveResponseForwarded = "flutter.notification-center.did-receive-response-forwarded"
    case flutterAppLifecycleState = "flutter.app-lifecycle-state"
    case flutterNotificationResponse = "flutter.notification-response"
    case expoSubscriberRegistered = "expo.subscriber-registered"
    case expoAppDelegateWillFinishLaunchingForwarded = "expo.app-delegate-will-finish-launching-forwarded"
    case expoAppDelegateDidFinishLaunchingForwarded = "expo.app-delegate-did-finish-launching-forwarded"
    case expoSubscriberDidBecomeActiveForwarded = "expo.subscriber.did-become-active-forwarded"
    case expoSubscriberWillResignActiveForwarded = "expo.subscriber.will-resign-active-forwarded"
    case expoSubscriberDidEnterBackgroundForwarded = "expo.subscriber.did-enter-background-forwarded"
    case expoSubscriberWillEnterForegroundForwarded = "expo.subscriber.will-enter-foreground-forwarded"
    case expoSubscriberWillTerminateForwarded = "expo.subscriber.will-terminate-forwarded"
    case expoSubscriberOpenURLForwarded = "expo.subscriber.open-url-forwarded"
    case expoSubscriberContinueUserActivityForwarded = "expo.subscriber.continue-user-activity-forwarded"
    case expoSubscriberPerformQuickActionForwarded = "expo.subscriber.perform-quick-action-forwarded"
    case expoSubscriberDidRegisterForRemoteNotificationsForwarded = "expo.subscriber.did-register-for-remote-notifications-forwarded"
    case expoSubscriberDidFailToRegisterForRemoteNotificationsForwarded = "expo.subscriber.did-fail-to-register-for-remote-notifications-forwarded"
    case expoSubscriberDidReceiveRemoteNotificationForwarded = "expo.subscriber.did-receive-remote-notification-forwarded"
    case expoSubscriberPerformBackgroundFetchForwarded = "expo.subscriber.perform-background-fetch-forwarded"
    case expoNotificationCenterManagerWillPresentForwarded = "expo.notification-center-manager.will-present-forwarded"
    case expoNotificationCenterManagerDidReceiveResponseForwarded = "expo.notification-center-manager.did-receive-response-forwarded"
    case expoNotificationsEmitterCreated = "expo.notifications-emitter-created"
    case expoNotificationsEmitterNotificationReceivedEventSent = "expo.notifications-emitter.notification-received-event-sent"
    case expoNotificationsEmitterNotificationResponseEventSent = "expo.notifications-emitter.notification-response-event-sent"
    case expoLastNotificationResponsePulled = "expo.last-notification-response-pulled"
    case hostRouteURL = "host.route-url"
    case hostRouteUserActivity = "host.route-user-activity"
    case hostRouteQuickAction = "host.route-quick-action"
    case hostRouteNotification = "host.route-notification"
    case hostPresentNotification = "host.present-notification"
    case hostBackgroundFetchCompletionResult = "host.background-fetch-completion-result"
    case customerIORouteDeepLink = "customerio.route-deep-link"
    case customerIOHandleNotificationResponse = "customerio.handle-notification-response"
    case customerIORegisterDeviceToken = "customerio.register-device-token"
    case wrapperAppReceivedURL = "wrapper.app-received-url"
    case wrapperAppReceivedUserActivity = "wrapper.app-received-user-activity"
    case wrapperAppReceivedNotification = "wrapper.app-received-notification"
    case wrapperAppReceivedQuickAction = "wrapper.app-received-quick-action"
    case wrapperAppLifecycleState = "wrapper.app-lifecycle-state"
    case traceScenarioStart = "trace.scenario-start"
    case traceScenarioEnd = "trace.scenario-end"
    case fixtureCompletionCreated = "fixture.completion-created"
    case fixtureCompletionObserved = "fixture.completion-observed"
}

public enum LifecycleTraceAliasNamespace: String, Codable, CaseIterable, Sendable {
    case delivery
    case request
    case scene
    case url
    case closure
}

public enum LifecycleTraceFlag: String, Sendable {
    case hasLaunchOptions = "has_launch_options"
    case hasURL = "has_url"
    case hasUserActivity = "has_user_activity"
    case hasScene = "has_scene"
    case hasNotification = "has_notification"
    case hasNotificationResponse = "has_notification_response"
    case hasShortcut = "has_shortcut"
    case hasAPS = "has_aps"
    case hasDeliveryID = "has_delivery_id"
    case hasDeliveryToken = "has_delivery_token"
    case hasRedirect = "has_redirect"
    case hasDeviceToken = "has_device_token"
    case hasFCMToken = "has_fcm_token"
    case handled
    case sceneManifestActive = "scene_manifest_active"
    case presentationAlert = "presentation_alert"
    case presentationBadge = "presentation_badge"
    case presentationSound = "presentation_sound"
    case presentationBanner = "presentation_banner"
    case presentationList = "presentation_list"
}

public enum LifecycleTraceCount: String, Sendable {
    case launchOptionKeys = "launch_option_keys"
    case urlContexts = "url_contexts"
    case userActivities = "user_activities"
    case payloadTopLevelKeys = "payload_top_level_keys"
    case notificationUserInfoKeys = "notification_user_info_keys"
    case deviceTokenBytes = "device_token_bytes"
    case fcmTokenCharacters = "fcm_token_characters"
    case urlPathComponents = "url_path_components"
    case urlQueryItems = "url_query_items"
    case connectedScenes = "connected_scenes"
    case discardedScenes = "discarded_scenes"
    case presentationOptions = "presentation_options"
}

public enum LifecycleTraceEnum: String, Sendable {
    case appState = "app_state"
    case urlScheme = "url_scheme"
    case urlClass = "url_class"
    case actionClass = "action_class"
    case activityClass = "activity_class"
    case sceneRole = "scene_role"
    case sceneState = "scene_state"
    case result
    case notificationOrigin = "notification_origin"
    case notificationClass = "notification_class"
    case delegatePeer = "delegate_peer"
    case presentationClass = "presentation_class"
    case errorClass = "error_class"
}

/// An opaque value retained only in the bounded, in-memory alias table.
public enum LifecycleTraceCorrelationValue: Hashable, Sendable {
    case string(String)
    case data(Data)
}

public struct LifecycleTraceObservation: Sendable {
    public var flags: [LifecycleTraceFlag: Bool]
    public var counts: [LifecycleTraceCount: Int]
    public var enums: [LifecycleTraceEnum: String]
    public var correlations: [LifecycleTraceAliasNamespace: LifecycleTraceCorrelationValue]

    public init(
        flags: [LifecycleTraceFlag: Bool] = [:],
        counts: [LifecycleTraceCount: Int] = [:],
        enums: [LifecycleTraceEnum: String] = [:],
        correlations: [LifecycleTraceAliasNamespace: LifecycleTraceCorrelationValue] = [:]
    ) {
        self.flags = flags
        self.counts = counts
        self.enums = enums
        self.correlations = correlations
    }

    public func merging(_ other: LifecycleTraceObservation) -> LifecycleTraceObservation {
        LifecycleTraceObservation(
            flags: flags.merging(other.flags) { _, new in new },
            counts: counts.merging(other.counts) { _, new in new },
            enums: enums.merging(other.enums) { _, new in new },
            correlations: correlations.merging(other.correlations) { _, new in new }
        )
    }
}

public struct LifecycleTraceContext: Equatable, Sendable {
    public let manifestID: String
    public let runID: String
    public let streamID: String
    public let processID: Int?
    public let processInstanceID: String
    public let integration: LifecycleTraceIntegration
    public let runtime: LifecycleTraceRuntime
    public let provider: LifecycleTraceProvider
    public let scenario: LifecycleTraceScenario
    public let evidenceLevel: LifecycleTraceEvidenceLevel

    public init?(
        manifestID: String,
        runID: String,
        streamID: String,
        processID: Int?,
        processInstanceID: String,
        integration: LifecycleTraceIntegration,
        runtime: LifecycleTraceRuntime,
        provider: LifecycleTraceProvider,
        scenario: LifecycleTraceScenario,
        evidenceLevel: LifecycleTraceEvidenceLevel
    ) {
        guard Self.isCanonicalUUID(manifestID),
              Self.isCanonicalUUID(runID),
              Self.isCanonicalUUID(streamID),
              Self.isCanonicalUUID(processInstanceID),
              processID == nil || (processID ?? 0) > 0 else {
            return nil
        }
        self.manifestID = manifestID
        self.runID = runID
        self.streamID = streamID
        self.processID = processID
        self.processInstanceID = processInstanceID
        self.integration = integration
        self.runtime = runtime
        self.provider = provider
        self.scenario = scenario
        self.evidenceLevel = evidenceLevel
    }

    private static func isCanonicalUUID(_ value: String) -> Bool {
        let pattern = "^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$"
        return value.range(of: pattern, options: .regularExpression) != nil
    }
}

public struct LifecycleTraceAliasCounts: Codable, Equatable, Sendable {
    public let delivery: Int
    public let request: Int
    public let scene: Int
    public let url: Int
    public let closure: Int

    public static let zero = LifecycleTraceAliasCounts(delivery: 0, request: 0, scene: 0, url: 0, closure: 0)
}

public struct LifecycleTraceRecorderSnapshot: Codable, Equatable, Sendable {
    public let droppedRecordsTotal: Int
    public let aliasCounts: LifecycleTraceAliasCounts
    public let aliasOverflow: Bool
    public let aliasOverflowNamespaces: [LifecycleTraceAliasNamespace]
    public let bufferHighWatermark: Int
    public let bufferCapacity: Int

    enum CodingKeys: String, CodingKey {
        case droppedRecordsTotal = "dropped_records_total"
        case aliasCounts = "alias_counts"
        case aliasOverflow = "alias_overflow"
        case aliasOverflowNamespaces = "alias_overflow_namespaces"
        case bufferHighWatermark = "buffer_high_watermark"
        case bufferCapacity = "buffer_capacity"
    }
}

public enum LifecycleTraceCompletionResult: String, Codable, Sendable {
    case invoked
    case notInvoked = "not-invoked"
}

public struct LifecycleTraceCompletion: Codable, Equatable, Sendable {
    public let owner = "fixture"
    public let closure: String
    public let parentSequence: Int
    public let observedCallCount: Int
    public let callIndex: Int?
    public let result: LifecycleTraceCompletionResult

    enum CodingKeys: String, CodingKey {
        case owner
        case closure
        case parentSequence = "parent_sequence"
        case observedCallCount = "observed_call_count"
        case callIndex = "call_index"
        case result
    }
}

public struct LifecycleTraceStreamReceipt: Codable, Equatable, Sendable {
    public let drainedAt: String
    public let lastAssignedSequence: Int
    public let lastEmittedSequence: Int
    public let emittedRecords: Int
    public let droppedRecordsTotal: Int
    public let bufferHighWatermark: Int
    public let bufferCapacity: Int
    public let aliasCounts: LifecycleTraceAliasCounts
    public let aliasOverflow: Bool
    public let aliasOverflowNamespaces: [LifecycleTraceAliasNamespace]

    enum CodingKeys: String, CodingKey {
        case drainedAt = "drained_at"
        case lastAssignedSequence = "last_assigned_sequence"
        case lastEmittedSequence = "last_emitted_sequence"
        case emittedRecords = "emitted_records"
        case droppedRecordsTotal = "dropped_records_total"
        case bufferHighWatermark = "buffer_high_watermark"
        case bufferCapacity = "buffer_capacity"
        case aliasCounts = "alias_counts"
        case aliasOverflow = "alias_overflow"
        case aliasOverflowNamespaces = "alias_overflow_namespaces"
    }
}
