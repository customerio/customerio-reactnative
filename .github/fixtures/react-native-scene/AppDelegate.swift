import CioMessagingPushAPN
import UIKit

@main
class AppDelegateWithCioIntegration: CioAppDelegateWrapper<AppDelegate> {}

class AppDelegate: UIResponder, UIApplicationDelegate {
  static let sceneConnectionProbeKey = "CIO_RN_SCENE_DID_CONNECT"
  static let warmDeepLinkCountKey = "CIO_RN_WARM_DEEP_LINK_COUNT"

  func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
  ) -> Bool {
    UserDefaults.standard.set(false, forKey: Self.sceneConnectionProbeKey)
    UserDefaults.standard.set(0, forKey: Self.warmDeepLinkCountKey)
    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
      guard UserDefaults.standard.bool(forKey: Self.sceneConnectionProbeKey) else {
        fatalError("SceneDelegate did not receive willConnectTo")
      }
    }
    return true
  }
}
