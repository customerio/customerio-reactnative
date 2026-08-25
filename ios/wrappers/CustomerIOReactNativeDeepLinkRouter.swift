import CioInternalCommon
import Foundation

enum CustomerIOReactNativeDeepLinkRouter {
    private static let sceneManifestKey = "UIApplicationSceneManifest"
    private static let sceneConfigurationsKey = "UISceneConfigurations"
    private static let sceneOpenURLContextsSelector = NSSelectorFromString("scene:openURLContexts:")
    // React Native 0.83.6 and 0.88.0-nightly-20260823-0c7f63a4e use this
    // notification name and payload for Linking URL events.
    private static let openURLNotification = Notification.Name("RCTOpenURLNotification")

    /// Mirrors `RCTIsSceneDelegateApp()` without linking to the internal symbol, and also requires
    /// React Native's scene-Linking entry point. A scene manifest alone does not make older React
    /// Native versions scene-aware.
    static var isSceneLifecycleEnabled: Bool {
        guard let manifest = Bundle.main.object(forInfoDictionaryKey: sceneManifestKey) as? [String: Any],
              let configurations = manifest[sceneConfigurationsKey] as? [String: Any]
        else { return false }
        guard !configurations.isEmpty,
              let linkingManager = NSClassFromString("RCTLinkingManager")
        else { return false }

        return linkingManager.responds(to: sceneOpenURLContextsSelector)
    }

    static func route(_ url: URL) {
        let publish = {
            // React Native's AppDelegate URL entry point rejects scene-based hosts. Linking listens
            // for this notification in both lifecycle modes, so publish the URL without choosing a scene.
            DIGraphShared.shared.logger.info(
                "Customer.io published an SDK deep link to React Native Linking"
            )
            NotificationCenter.default.post(
                name: openURLNotification,
                object: nil,
                userInfo: ["url": url.absoluteString]
            )
        }
        if Thread.isMainThread {
            publish()
        } else {
            DispatchQueue.main.async(execute: publish)
        }
    }
}
