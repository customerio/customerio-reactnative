import UIKit
import React
import CioMessagingPushFCM
import CioTracking
import Firebase
import FirebaseMessaging

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
  
  let moduleName: String = "FCMSampleApp"
  let initialProps: [AnyHashable: Any] = [:]
  var window: UIWindow?

  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    // Add custom initialization code here
    // This fixes an issue in which the React Native SDK identifies a profile, but an iOS device isn't added to the profile.
    // Important to call this code before calling `registerForRemoteNotifications`.
    CustomerIO.initialize(siteId: Env.siteId, apiKey: Env.apiKey, region: .US) { config in
      config.autoTrackPushEvents = true
      config.logLevel = .debug
    }

    // Configure Firebase
    FirebaseApp.configure()
    
    var modifiedLaunchOptions = launchOptions

    if let options = launchOptions,
       options[UIApplication.LaunchOptionsKey.url] == nil,
       let pushContent = options[UIApplication.LaunchOptionsKey.remoteNotification] as? [String: Any],
       let cioContent = pushContent["CIO"] as? [String: Any],
       let pushContent = cioContent["push"] as? [String: Any],
       let initialLink = pushContent["link"] as? String {
      modifiedLaunchOptions![UIApplication.LaunchOptionsKey.url] = NSURL(string: initialLink)
    }
    
    let bridge = RCTBridge(delegate: self, launchOptions: modifiedLaunchOptions)!
    let rootView = RCTRootView(bridge: bridge, moduleName: moduleName, initialProperties: initialProps)
    rootView.backgroundColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1)
    self.window = UIWindow(frame: UIScreen.main.bounds)
    let rootViewController = UIViewController()
    rootViewController.view = rootView
    self.window?.rootViewController = rootViewController
    self.window?.makeKeyAndVisible()

    // Now that the Firebase and Customer.io SDK's are initialized, follow the rest of the required steps for the FCM push setup.
    UNUserNotificationCenter.current().delegate = self
    
    // Set FCM messaging delegate
    Messaging.messaging().delegate = self
    
    // Uncomment only if you want to register for remote push when the app starts
    // UIApplication.shared.registerForRemoteNotifications()
    
    return true
  }
  
  func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
    return RCTLinkingManager.application(app, open: url, options: options)
  }
  
  func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
    return RCTLinkingManager.application(application, continue: userActivity, restorationHandler: restorationHandler)
  }
}

extension AppDelegate: RCTBridgeDelegate {
  func sourceURL(for bridge: RCTBridge!) -> URL! {
    return RCTBundleURLProvider.sharedSettings().jsBundleURL(forBundleRoot: "index")
  }
}

extension AppDelegate: MessagingDelegate {
  func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
    MessagingPush.shared.messaging(messaging, didReceiveRegistrationToken: fcmToken)
  }
  
  func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
      MessagingPush.shared.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
  }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    // OPTIONAL: If you want your push UI to show even with the app in the foreground, override this function and call
    // the completion handler.
    @available(iOS 10.0, *)
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions)
            -> Void
    ) {
        completionHandler([.list, .banner, .badge, .sound])
    }

    // Function that gets called when push notification clicked
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        // Send Customer.io SDK click event to process. This enables features such as
        // push metrics and deep links.
        let handled = MessagingPush.shared.userNotificationCenter(
            center,
            didReceive: response,
            withCompletionHandler: completionHandler
        )

        // If the Customer.io SDK does not handle the push, it's up to you to handle it and call the
        // completion handler. If the SDK did handle it, it called the completion handler for you.
        if !handled {
            completionHandler()
        }
    }
}
