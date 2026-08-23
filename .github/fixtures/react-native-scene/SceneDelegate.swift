import CioInternalCommon
import React
import ReactAppDependencyProvider
import React_RCTAppDelegate
import UIKit

class SceneDelegate: RCTDefaultReactNativeFactoryDelegate, UIWindowSceneDelegate {
  var window: UIWindow?
  var reactNativeFactory: RCTReactNativeFactory?

  func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    UserDefaults.standard.set(true, forKey: AppDelegate.sceneConnectionProbeKey)

    guard let windowScene = scene as? UIWindowScene else {
      return
    }

    dependencyProvider = RCTAppDependencyProvider()
    reactNativeFactory = RCTReactNativeFactory(delegate: self)
    window = UIWindow(windowScene: windowScene)

    reactNativeFactory?.startReactNative(
      withModuleName: "CioRnSceneHost",
      in: window,
      connectionOptions: connectionOptions
    )

    DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
      DIGraphShared.shared.deepLinkUtil.handleDeepLink(
        URL(string: "https://customer.io/react-native-scene-validation")!
      )
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + 25) {
      guard UserDefaults.standard.bool(forKey: AppDelegate.deepLinkProbeKey) else {
        fatalError("Customer.io scene deep link did not reach React Native Linking")
      }
    }
  }

  func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
    if URLContexts.contains(where: { $0.url.absoluteString == "cio-rn-scene-validation://received" }) {
      UserDefaults.standard.set(true, forKey: AppDelegate.deepLinkProbeKey)
      return
    }
    RCTLinkingManager.scene(scene, openURLContexts: URLContexts)
  }

  func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
    RCTLinkingManager.scene(scene, continue: userActivity)
  }

  override func bundleURL() -> URL? {
    #if DEBUG
    RCTBundleURLProvider.sharedSettings().jsBundleURL(forBundleRoot: "index")
    #else
    Bundle.main.url(forResource: "main", withExtension: "jsbundle")
    #endif
  }
}
