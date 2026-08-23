import UIKit

final class CustomerIOReactNativeDeepLinkRouter {
    private static let sceneManifestKey = "UIApplicationSceneManifest"

    static var isSceneLifecycleEnabled: Bool {
        Bundle.main.object(forInfoDictionaryKey: sceneManifestKey) != nil
    }

    func route(_ url: URL) {
        DispatchQueue.main.async {
            if RCTLinkingManager.application(UIApplication.shared, open: url, options: [:]) {
                return
            }

            UIApplication.shared.open(url)
        }
    }
}
