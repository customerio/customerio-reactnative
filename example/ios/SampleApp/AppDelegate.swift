import UIKit
import React
import React_RCTAppDelegate
import ReactAppDependencyProvider

import UserNotifications
// Wrapper pod module — exposes NativeLiveActivities for reporting a Live Activity deep-link open.
import customerio_reactnative

#if canImport(CioLocationGeofence)
import CioLocationGeofence
#endif

#if USE_FCM
import FirebaseMessaging
import FirebaseCore
import CioMessagingPushFCM
import CioFirebaseWrapper

typealias CioMessagingPushHandler = MessagingPushFCM

let UNIVERSAL_LINK_URL = URL(string: "http://www.amiapp-reactnative-fcm.com")!

#else
import CioMessagingPushAPN

typealias CioMessagingPushHandler = MessagingPushAPN

let UNIVERSAL_LINK_URL = URL(string: "http://www.amiapp-reactnative-apns.com")!
#endif

private let sampleLifecycleTraceRecorder = LifecycleTraceHarness.configureFromEnvironment(
  sink: ConsoleLifecycleTraceSink()
)
private let sampleLifecycleTraceProbeObserver = sampleLifecycleTraceRecorder.map { _ in
  LifecycleTracePlatformProbeObserver()
}

@main
class AppDelegateWithCioIntegration: CioAppDelegateWrapper<AppDelegate> {}

class AppDelegate: UIResponder, UIApplicationDelegate {
  var window: UIWindow?

  var reactNativeDelegate: ReactNativeDelegate?
  var reactNativeFactory: RCTReactNativeFactory?

  func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
  ) -> Bool {
    _ = sampleLifecycleTraceRecorder
    _ = sampleLifecycleTraceProbeObserver
    LifecycleTraceHarness.startScenario()
    recordColdStartLaunch(application, launchOptions: launchOptions)

    #if canImport(CioLocationGeofence)
    // Geofence cold-wake delivery: iOS can launch the app into the background for a
    // geofence transition without starting the JS runtime, so the SDK can't rely on
    // CustomerIO.initialize running. Bootstrapping here wires up region monitoring and
    // flushes queued transitions on every launch; it is safe alongside normal init.
    GeofenceModule.bootstrapForBackgroundDelivery(launchOptions: launchOptions)
    #endif

    let delegate = ReactNativeDelegate()
    let factory = RCTReactNativeFactory(delegate: delegate)
    delegate.dependencyProvider = RCTAppDependencyProvider()

    reactNativeDelegate = delegate
    reactNativeFactory = factory

    window = UIWindow(frame: UIScreen.main.bounds)
    
    
    let remotePush = launchOptions?[UIApplication.LaunchOptionsKey.remoteNotification] as? [String: [String: [String: String]]]
    if let link = remotePush?["CIO"]?["push"]?["link"], let url = URL(string:link) {
      var launchOptions = launchOptions ?? [:]
      if launchOptions[UIApplication.LaunchOptionsKey.url] == nil {
        launchOptions[UIApplication.LaunchOptionsKey.url] = url
      }
    }
    
    let appName = Bundle.main.displayName
    
    factory.startReactNative(
      withModuleName: appName,
      in: window,
      initialProperties: ["appName": appName],
      launchOptions: launchOptions
    )
    
    #if USE_FCM
    FirebaseApp.configure()
    Messaging.messaging().delegate = self
    #endif
    
    
    CioMessagingPushHandler.initialize(
        withConfig: MessagingPushConfigBuilder()
            .appGroupId("group.io.customer.ami.cio")
            .build()
    )
    
    return true
  }
  
}

// MARK: Deep linking
extension AppDelegate {
  func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
    let routeEvidence = LifecycleTraceEvidence.observe(url: url)
    LifecycleTraceProbe.post(
      callback: .applicationOpenURL,
      owner: .applicationDelegate,
      kind: .osCallback,
      phase: .entry,
      observations: LifecycleTraceEvidence.observe(applicationState: app.applicationState), routeEvidence
    )
    LifecycleTraceProbe.post(
      callback: .hostRouteURL,
      owner: .host,
      kind: .hostRouting,
      phase: .intent,
      observations: routeEvidence
    )

    // Reference pattern: report the "opened" metric when the app is launched from a tapped Live
    // Activity. A Live Activity tap arrives here (the app's URL entry point), not through JS, so the
    // host app forwards the URL to the wrapper. For a Customer.io widget URL this returns the
    // customer's redirect target to route to (nil when it carries none); any other URL comes back
    // unchanged, so existing deep links keep working.
    let isCustomerIOLiveActivityURL = LifecycleTraceEvidence.isCustomerIOLiveActivityRoute(url)
    if isCustomerIOLiveActivityURL {
      LifecycleTraceProbe.post(
        callback: .customerIORouteDeepLink,
        owner: .customerIOSDK,
        kind: .sdkRouting,
        phase: .intent,
        observations: routeEvidence
      )
    }
    let routableUrl = NativeLiveActivities.handleWidgetUrl(url)
    if isCustomerIOLiveActivityURL {
      LifecycleTraceProbe.post(
        callback: .customerIORouteDeepLink,
        owner: .customerIOSDK,
        kind: .sdkRouting,
        phase: .result,
        observations: routeEvidence,
        LifecycleTraceEvidence.observe(
          routingResult: Self.liveActivityRoutingResult(original: url, destination: routableUrl)
        )
      )
    }
    guard let routableUrl else {
      recordHostURLResult(evidence: routeEvidence, handled: true)
      return true
    }

    let handled = RCTLinkingManager.application(app, open: routableUrl, options: options)
    recordHostURLResult(evidence: routeEvidence, handled: handled)
    return handled
  }
  
  func application(
    _ application: UIApplication,
    continue userActivity: NSUserActivity,
    restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
      let routeEvidence = LifecycleTraceEvidence.observe(userActivity: userActivity)
      LifecycleTraceProbe.post(
        callback: .applicationContinueUserActivity,
        owner: .applicationDelegate,
        kind: .osCallback,
        phase: .entry,
        observations: LifecycleTraceEvidence.observe(applicationState: application.applicationState), routeEvidence
      )
      LifecycleTraceProbe.post(
        callback: .hostRouteUserActivity,
        owner: .host,
        kind: .hostRouting,
        phase: .intent,
        observations: routeEvidence
      )

      let handled: Bool
      if let url = userActivity.webpageURL, (url.scheme == "http" || url.scheme == "https") && url.host() == UNIVERSAL_LINK_URL.host() {
        handled = RCTLinkingManager.application(
          application,
          continue: userActivity,
          restorationHandler: restorationHandler
        )
      } else {
        handled = false
      }

      LifecycleTraceProbe.post(
        callback: .hostRouteUserActivity,
        owner: .host,
        kind: .hostRouting,
        phase: .result,
        observations: routeEvidence,
        LifecycleTraceEvidence.observe(routingResult: handled ? .handled : .unhandled)
      )
      LifecycleTraceHarness.endScenario(after: .hostUserActivityRoute)
      return handled
    }

  private static func liveActivityRoutingResult(
    original: URL,
    destination: URL?
  ) -> LifecycleTraceRoutingResult {
    guard let destination else { return .handled }
    return destination == original ? .unhandled : .redirect
  }

  private func recordColdStartLaunch(
    _ application: UIApplication,
    launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) {
    guard LifecycleTraceHarness.sharedRecorder?.scenario.isColdStart == true else { return }
    LifecycleTraceProbe.post(
      callback: .applicationDidFinishLaunching,
      owner: .applicationDelegate,
      kind: .osCallback,
      phase: .entry,
      observations:
        LifecycleTraceEvidence.observe(applicationState: application.applicationState),
        LifecycleTraceEvidence.observe(launchOptions: launchOptions)
    )
  }

  private func recordHostURLResult(evidence: LifecycleTraceObservation, handled: Bool) {
    LifecycleTraceProbe.post(
      callback: .hostRouteURL,
      owner: .host,
      kind: .hostRouting,
      phase: .result,
      observations: evidence,
      LifecycleTraceEvidence.observe(routingResult: handled ? .handled : .unhandled)
    )
    LifecycleTraceHarness.endScenario(after: .hostURLRoute)
  }
}

// MARK: Push setup

#if USE_FCM

extension AppDelegate: MessagingDelegate {
  func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
      // Not needed when CioAppDelegateWrapper is used
//    MessagingPush.shared.messaging(messaging, didReceiveRegistrationToken: fcmToken)
  }
}

#else
extension AppDelegate {
  func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
      // Not needed when CioAppDelegateWrapper is used
//    MessagingPush.shared.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }
  
  func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: any Error) {
      // Not needed when CioAppDelegateWrapper is used
//    MessagingPush.shared.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
  }
}

#endif


// MARK: React Native Setup
class ReactNativeDelegate: RCTDefaultReactNativeFactoryDelegate {
  override func sourceURL(for bridge: RCTBridge) -> URL? {
    self.bundleURL()
  }

  override func bundleURL() -> URL? {
#if DEBUG
    RCTBundleURLProvider.sharedSettings().jsBundleURL(forBundleRoot: "index")
#else
    Bundle.main.url(forResource: "main", withExtension: "jsbundle")
#endif
  }
}

// MARK: React Native Sample App Utils
extension Bundle {
  var displayName: String {
    let name = object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
    return name ?? object(forInfoDictionaryKey: kCFBundleNameKey as String) as! String
  }
}
