@_spi(Internal) import CioInternalCommon
import Foundation
import UIKit

enum CustomerIOReactNativeDeepLinkRouter {
    private static let readinessTimeout: TimeInterval = 10
    private static let acknowledgementTimeout: TimeInterval = 10
    private static let sceneManifestKey = "UIApplicationSceneManifest"
    private static let sceneConfigurationsKey = "UISceneConfigurations"
    private static let sceneOpenURLContextsSelector = NSSelectorFromString("scene:openURLContexts:")
    // React Native 0.83.6 and 0.88.0-nightly-20260823-0c7f63a4e use this
    // notification name and payload for Linking URL events.
    private static let openURLNotification = Notification.Name("RCTOpenURLNotification")
    private static let stateLock = NSLock()
    private static var requestStore = CustomerIOReactNativeDeepLinkRequestStore()
    private static var handlerEmitter: ((_ id: String, _ url: String) -> Void)?
    private static var handlerToken: UUID?

    static var requiresAcknowledgedHandler: Bool {
        stateLock.lock()
        defer { stateLock.unlock() }
        return requestStore.requiresAcknowledgedHandler
    }

    private static var hasSceneManifest: Bool {
        guard let manifest = Bundle.main.object(forInfoDictionaryKey: sceneManifestKey) as? [String: Any],
              let configurations = manifest[sceneConfigurationsKey] as? [String: Any]
        else { return false }

        return !configurations.isEmpty
    }

    /// Mirrors `RCTIsSceneDelegateApp()` without linking to the internal symbol, and also requires
    /// React Native's scene-Linking entry point. A scene manifest alone does not make older React
    /// Native versions scene-aware.
    static var isSceneLifecycleEnabled: Bool {
        guard hasSceneManifest,
              let linkingManager = NSClassFromString("RCTLinkingManager")
        else { return false }

        return linkingManager.responds(to: sceneOpenURLContextsSelector)
    }

    /// Expo owns scene-to-Linking forwarding even when its React Native version does not expose
    /// the scene selector itself.
    static var isExpoSceneLifecycleEnabled: Bool {
        hasSceneManifest && NSClassFromString("EXExpoAppSceneDelegate") != nil
    }

    static func install() {
        guard isSceneLifecycleEnabled else { return }
        installCallback(requiringAcknowledgedHandler: false)
    }

    static func installAcknowledgedHandler() {
        guard isSceneLifecycleEnabled else {
            DIGraphShared.shared.logger.error(
                "Customer.io could not install acknowledged deep-link routing because the host " +
                    "does not expose a supported React Native scene lifecycle"
            )
            return
        }
        installCallback(requiringAcknowledgedHandler: true)
    }

    /// Expo owns scene-to-Linking forwarding even on React Native versions that do not expose the
    /// scene selector themselves. Prefer the generic React Native capability when available, then
    /// fall back to Expo's scene delegate capability.
    static func installForExpoSceneLifecycle() {
        guard isSceneLifecycleEnabled || isExpoSceneLifecycleEnabled else {
            DIGraphShared.shared.logger.error(
                "Customer.io could not install Expo scene deep-link routing because the host " +
                    "does not expose a supported React Native or Expo scene lifecycle"
            )
            return
        }
        installCallback(requiringAcknowledgedHandler: false)
    }

    private static func installCallback(requiringAcknowledgedHandler: Bool) {
        stateLock.lock()
        if requiringAcknowledgedHandler {
            requestStore.requireAcknowledgedHandler()
        }
        stateLock.unlock()
        DIGraphShared.shared.deepLinkUtil.setDeepLinkCallback { url in
            accept(url)
            return true
        }
    }

    static func accept(_ url: URL) {
        stateLock.lock()
        let acceptance = requestStore.accept(url)
        stateLock.unlock()

        switch acceptance {
        case let .buffered(id):
            DIGraphShared.shared.logger.info(
                "Customer.io buffered an SDK deep link until a React Native route is ready"
            )
            scheduleReadinessExpiration(for: id)
        case let .linking(url):
            route(url)
        case let .handler(id, url):
            publishToHandler(id: id, url: url)
        }
    }

    static func markReactNativeReady() {
        let markReady = {
            stateLock.lock()
            let urls = requestStore.useLinking()
            stateLock.unlock()

            urls.forEach(route)
        }
        if Thread.isMainThread {
            markReady()
        } else {
            DispatchQueue.main.async(execute: markReady)
        }
    }

    static func registerHandler(
        _ emitter: @escaping (_ id: String, _ url: String) -> Void
    ) -> UUID {
        let token = UUID()
        stateLock.lock()
        let hasAcknowledgedHandlerConfiguration = requestStore.requiresAcknowledgedHandler
        handlerToken = token
        handlerEmitter = emitter
        let deliveries = requestStore.useHandler()
        stateLock.unlock()

        if !hasAcknowledgedHandlerConfiguration {
            DIGraphShared.shared.logger.error(
                "Customer.io registered an acknowledged deep-link handler without configuring " +
                    "acknowledged scene routing before React Native started"
            )
        }
        for (id, url) in deliveries {
            publishToHandler(id: id, url: url)
        }
        return token
    }

    static func unregisterHandler(_ token: UUID) {
        stateLock.lock()
        guard handlerToken == token else {
            stateLock.unlock()
            return
        }
        handlerToken = nil
        handlerEmitter = nil
        requestStore.removeHandler()
        stateLock.unlock()
    }

    static func acknowledge(_ id: String, handled: Bool) {
        guard let requestId = UUID(uuidString: id) else {
            DIGraphShared.shared.logger.error(
                "Customer.io ignored an invalid React Native deep-link acknowledgement"
            )
            return
        }

        stateLock.lock()
        let resolution = requestStore.acknowledge(requestId, handled: handled)
        stateLock.unlock()

        switch resolution {
        case .handled:
            DIGraphShared.shared.logger.info(
                "React Native acknowledged the Customer.io deep link"
            )
        case let .fallback(url):
            DIGraphShared.shared.logger.info(
                "React Native declined the Customer.io deep link; using the native fallback"
            )
            fallback(url)
        case nil:
            DIGraphShared.shared.logger.info(
                "Customer.io ignored a late or unknown React Native deep-link acknowledgement; " +
                    "the native fallback may have already routed the destination"
            )
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

    private static func publishToHandler(id: UUID, url: URL) {
        let publish = {
            stateLock.lock()
            let emitter = handlerEmitter
            stateLock.unlock()

            emitter?(id.uuidString, url.absoluteString)
            DispatchQueue.main.asyncAfter(deadline: .now() + acknowledgementTimeout) {
                expireAcknowledgement(id)
            }
        }
        if Thread.isMainThread {
            publish()
        } else {
            DispatchQueue.main.async(execute: publish)
        }
    }

    private static func scheduleReadinessExpiration(for id: UUID) {
        DispatchQueue.main.asyncAfter(deadline: .now() + readinessTimeout) {
            expireReadiness(id)
        }
    }

    private static func expireReadiness(_ id: UUID) {
        stateLock.lock()
        let url = requestStore.expireReadiness(id)
        stateLock.unlock()

        guard let url else { return }

        DIGraphShared.shared.logger.error(
            "Customer.io is using the native fallback because React Native deep-link routing " +
                "did not become ready in time"
        )
        fallback(url)
    }

    private static func expireAcknowledgement(_ id: UUID) {
        stateLock.lock()
        let url = requestStore.expireAcknowledgement(id)
        stateLock.unlock()

        guard let url else { return }

        DIGraphShared.shared.logger.error(
            "Customer.io is using the native fallback because the React Native deep-link " +
                "handler did not acknowledge the URL in time"
        )
        fallback(url)
    }

    private static func fallback(_ url: URL) {
        let open = {
            let uiKit = DIGraphShared.shared.uIKitWrapper
            if uiKit.continueNSUserActivity(webpageURL: url) {
                DIGraphShared.shared.logger.info(
                    "Customer.io deep link was handled by the host AppDelegate fallback"
                )
            } else if isAppOwnedCustomScheme(url) {
                stateLock.lock()
                let linkingIsReady = requestStore.canDeliverWithLinking
                stateLock.unlock()
                route(url)
                if linkingIsReady {
                    DIGraphShared.shared.logger.info(
                        "Customer.io forwarded the host app's custom-scheme deep link to React " +
                            "Native Linking"
                    )
                } else {
                    DIGraphShared.shared.logger.error(
                        "Customer.io published the host app's custom-scheme deep link before " +
                            "React Native Linking was marked ready; the destination may not be handled"
                    )
                }
            } else {
                uiKit.open(url: url)
                DIGraphShared.shared.logger.info(
                    "Customer.io opened the deep link through the system fallback"
                )
            }
        }
        if Thread.isMainThread {
            open()
        } else {
            DispatchQueue.main.async(execute: open)
        }
    }

    private static func isAppOwnedCustomScheme(_ url: URL) -> Bool {
        guard let scheme = url.scheme,
              scheme.caseInsensitiveCompare("http") != .orderedSame,
              scheme.caseInsensitiveCompare("https") != .orderedSame,
              let urlTypes = Bundle.main.object(forInfoDictionaryKey: "CFBundleURLTypes")
              as? [[String: Any]]
        else { return false }

        return urlTypes.contains { urlType in
            guard let schemes = urlType["CFBundleURLSchemes"] as? [String] else { return false }
            return schemes.contains { $0.caseInsensitiveCompare(scheme) == .orderedSame }
        }
    }
}
