import UIKit

final class CustomerIOReactNativeDeepLinkRouter {
    private static let sceneManifestKey = "UIApplicationSceneManifest"

    static var isSceneLifecycleEnabled: Bool {
        // UIKit enables the scene lifecycle when the scene manifest is present.
        Bundle.main.object(forInfoDictionaryKey: sceneManifestKey) != nil
    }

    static func route(_ url: URL) {
        DispatchQueue.main.async {
            _ = RCTLinkingManager.application(UIApplication.shared, open: url, options: [:])
        }
    }
}
