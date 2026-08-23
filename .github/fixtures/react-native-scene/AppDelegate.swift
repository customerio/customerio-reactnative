import CioMessagingPushAPN
import UIKit

@main
class AppDelegateWithCioIntegration: CioAppDelegateWrapper<AppDelegate> {}

class AppDelegate: UIResponder, UIApplicationDelegate {
  static let sceneConnectionProbeKey = "CIO_RN_SCENE_DID_CONNECT"
  static let deepLinkProbeKey = "CIO_RN_DEEP_LINK_RECEIVED"

  func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
  ) -> Bool {
    UserDefaults.standard.set(false, forKey: Self.sceneConnectionProbeKey)
    UserDefaults.standard.set(false, forKey: Self.deepLinkProbeKey)
    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
      guard UserDefaults.standard.bool(forKey: Self.sceneConnectionProbeKey) else {
        fatalError("SceneDelegate did not receive willConnectTo")
      }
    }
    return true
  }
}
