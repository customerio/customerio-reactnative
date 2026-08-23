import CioInternalCommon
import React
import ReactAppDependencyProvider
import React_RCTAppDelegate
import UIKit
import customerio_reactnative

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
      launchOptions: NativeLiveActivities.reactNativeLaunchOptions(from: connectionOptions)
    )

    if connectionOptions.urlContexts.isEmpty {
      DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
        DIGraphShared.shared.deepLinkUtil.handleDeepLink(
          URL(string: "https://customer.io/react-native-scene-validation")!
        )
      }
      DispatchQueue.main.asyncAfter(deadline: .now() + 25) {
        guard UserDefaults.standard.integer(forKey: AppDelegate.warmDeepLinkCountKey) == 1 else {
          fatalError("Customer.io warm scene deep link was not delivered exactly once")
        }
      }
    }
  }

  func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
    for context in URLContexts {
      switch context.url.absoluteString {
      case "cio-rn-scene-validation://warm-received":
        increment(AppDelegate.warmDeepLinkCountKey)
      default:
        NativeLiveActivities.handleAndRouteWidgetUrl(context.url)
      }
    }
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

  private func increment(_ key: String) {
    let defaults = UserDefaults.standard
    defaults.set(defaults.integer(forKey: key) + 1, forKey: key)
  }
}
