import UIKit
import React
import React_RCTAppDelegate
import ReactAppDependencyProvider

import UserNotifications

#if USE_FCM
import FirebaseMessaging
import FirebaseCore
import CioMessagingPushFCM

typealias CioMessagingPushHandler = MessagingPushFCM

let UNIVERSAL_LINK_URL = URL(string: "http://www.amiapp-reactnative-fcm.com")!

#else
import CioMessagingPushAPN

typealias CioMessagingPushHandler = MessagingPushAPN

let UNIVERSAL_LINK_URL = URL(string: "http://www.amiapp-reactnative-apns.com")!
#endif

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
    
    
    CioMessagingPushHandler.initialize(withConfig: MessagingPushConfigBuilder().build())
    
    
    return true
  }
  
}

// MARK: Deep linking
extension AppDelegate {
  func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
    return RCTLinkingManager.application(app, open: url, options: options)
  }
  
  func application(
    _ application: UIApplication,
    continue userActivity: NSUserActivity,
    restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
      if let url = userActivity.webpageURL, (url.scheme == "http" || url.scheme == "https") && url.host() == UNIVERSAL_LINK_URL.host() {
        return RCTLinkingManager.application(
          application,
          continue: userActivity,
          restorationHandler: restorationHandler
        )
      }
      
      return false
      
    }
}

// MARK: Push setup

#if USE_FCM

extension AppDelegate: MessagingDelegate {
  func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
    MessagingPush.shared.messaging(messaging, didReceiveRegistrationToken: fcmToken)
  }
}

#else
extension AppDelegate {
  func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    MessagingPush.shared.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }
  
  func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: any Error) {
    MessagingPush.shared.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
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
