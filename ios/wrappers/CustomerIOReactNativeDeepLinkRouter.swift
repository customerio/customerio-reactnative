import UIKit

final class CustomerIOReactNativeDeepLinkRouter {
    private static let sceneManifestKey = "UIApplicationSceneManifest"

    static var isSceneLifecycleEnabled: Bool {
        // React Native uses the scene-manifest key as its scene-lifecycle switch.
        Bundle.main.object(forInfoDictionaryKey: sceneManifestKey) != nil
    }

    static func route(_ url: URL) {
        DispatchQueue.main.async {
            _ = RCTLinkingManager.application(UIApplication.shared, open: url, options: [:])
        }
    }
}
