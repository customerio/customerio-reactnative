import Foundation

final class CustomerIOReactNativeDeepLinkRouter {
    private static let sceneManifestKey = "UIApplicationSceneManifest"
    private static let sceneConfigurationsKey = "UISceneConfigurations"
    // React Native 0.83.6 and 0.88.0-nightly-20260823-0c7f63a4e use this
    // notification name and payload for Linking URL events.
    private static let openURLNotification = Notification.Name("RCTOpenURLNotification")

    /// Mirrors `RCTIsSceneDelegateApp()` as verified in React Native
    /// 0.88.0-nightly-20260823-0c7f63a4e without linking to the internal symbol, so the wrapper
    /// continues to compile against older supported versions.
    static var isSceneLifecycleEnabled: Bool {
        guard let manifest = Bundle.main.object(forInfoDictionaryKey: sceneManifestKey) as? [String: Any],
              let configurations = manifest[sceneConfigurationsKey] as? [String: Any]
        else { return false }
        return !configurations.isEmpty
    }

    static func route(_ url: URL) {
        DispatchQueue.main.async {
            // React Native's AppDelegate URL entry point rejects scene-based hosts. Linking listens
            // for this notification in both lifecycle modes, so publish the URL without choosing a scene.
            NotificationCenter.default.post(
                name: openURLNotification,
                object: nil,
                userInfo: ["url": url.absoluteString]
            )
        }
    }
}
