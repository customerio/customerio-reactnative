@_spi(Internal) import CioInternalCommon
import Foundation
import UIKit

enum CustomerIOReactNativeDeepLinkRouter {
    private struct PendingUrl {
        let id: UUID
        let url: URL
    }

    private static let readinessTimeout: TimeInterval = 10
    private static let sceneManifestKey = "UIApplicationSceneManifest"
    private static let sceneConfigurationsKey = "UISceneConfigurations"
    private static let sceneOpenURLContextsSelector = NSSelectorFromString("scene:openURLContexts:")
    // React Native 0.83.6 and 0.88.0-nightly-20260823-0c7f63a4e use this
    // notification name and payload for Linking URL events.
    private static let openURLNotification = Notification.Name("RCTOpenURLNotification")
    private static let stateLock = NSLock()
    // React Native Linking is process-wide. Multi-window and independent bridge lifecycles are
    // outside the single-window scene contract, so readiness intentionally lasts for the process.
    private static var isReactNativeReady = false
    private static var pendingUrls: [PendingUrl] = []

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

    static func install() {
        guard isSceneLifecycleEnabled else { return }

        DIGraphShared.shared.deepLinkUtil.setDeepLinkCallback { url in
            accept(url)
            return true
        }
    }

    static func accept(_ url: URL) {
        stateLock.lock()
        if !isReactNativeReady {
            let pendingUrl = PendingUrl(id: UUID(), url: url)
            pendingUrls.append(pendingUrl)
            stateLock.unlock()
            DispatchQueue.main.asyncAfter(deadline: .now() + readinessTimeout) {
                expire(pendingUrl.id)
            }
            return
        }
        stateLock.unlock()

        route(url)
    }

    static func markReactNativeReady() {
        let markReady = {
            stateLock.lock()
            isReactNativeReady = true
            let urls = pendingUrls.map(\.url)
            pendingUrls.removeAll()
            stateLock.unlock()

            // This runs on the main thread, so buffered URLs are published before a new
            // main-thread URL can interleave with them.
            urls.forEach(route)
        }
        if Thread.isMainThread {
            markReady()
        } else {
            DispatchQueue.main.async(execute: markReady)
        }
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

    private static func expire(_ id: UUID) {
        stateLock.lock()
        guard !isReactNativeReady,
              let index = pendingUrls.firstIndex(where: { $0.id == id })
        else {
            stateLock.unlock()
            return
        }
        let url = pendingUrls.remove(at: index).url
        stateLock.unlock()

        DIGraphShared.shared.logger.error(
            "Customer.io is opening an SDK deep link externally because React Native did not initialize in time"
        )
        UIApplication.shared.open(url) { opened in
            guard !opened else { return }
            DIGraphShared.shared.logger.error(
                "Customer.io could not open the SDK deep link externally"
            )
        }
    }
}
