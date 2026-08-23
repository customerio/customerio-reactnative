import Foundation

final class CustomerIOReactNativeDeepLinkRouter {
    private static let sceneManifestKey = "UIApplicationSceneManifest"
    private static let openURLNotification = Notification.Name("RCTOpenURLNotification")

    static var isSceneLifecycleEnabled: Bool {
        // UIKit enables the scene lifecycle when the scene manifest is present.
        Bundle.main.object(forInfoDictionaryKey: sceneManifestKey) != nil
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
