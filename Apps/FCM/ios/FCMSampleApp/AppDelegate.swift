import UIKit
import React

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var moduleName: String = "FCMSampleApp"
    var initialProps: [AnyHashable: Any] = [:]

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
      // Add custom initialization code here
      return true
    }

    func sourceURL(for bridge: RCTBridge!) -> URL! {
        #if DEBUG
            return RCTBundleURLProvider.sharedSettings().jsBundleURL(forBundleRoot: "index", fallbackResource: nil)
        #else
            return Bundle.main.url(forResource: "main", withExtension: "jsbundle")
        #endif
    }
}
