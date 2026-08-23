import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
  static let sceneConnectionProbeKey = "CIO_RN_SCENE_DID_CONNECT"

  func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
  ) -> Bool {
    UserDefaults.standard.set(false, forKey: Self.sceneConnectionProbeKey)
    DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
      guard UserDefaults.standard.bool(forKey: Self.sceneConnectionProbeKey) else {
        fatalError("SceneDelegate did not receive willConnectTo")
      }
    }
    return true
  }
}
