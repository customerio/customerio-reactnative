import CioAnalytics
import CioDataPipelines
import CioInternalCommon
import CioMessagingInApp
import Foundation

@objc(NativeCustomerIO)
public class NativeCustomerIO: NSObject {
    private let logger: CioInternalCommon.Logger = DIGraphShared.shared.logger
    private weak var objcEventEmitter: AnyObject?
    private var deepLinkHandlerToken: UUID?
    /// Checks whether the CustomerIO SDK has been initialized.
    /// Returns `true` if the SDK has been successfully initialized, `false` otherwise.
    private var isInitialized: Bool { CustomerIO.shared.implementation != nil }

    /// Installs React Native scene deep-link routing before the JavaScript bridge starts.
    /// Call this at the start of `scene(_:willConnectTo:options:)` in a UIScene host.
    @objc
    public static func configureSceneDeepLinkRouting() {
        // A natively initialized host owns its callback. Scene connection happens after
        // application launch, so never replace a callback that native initialization installed.
        guard CustomerIO.shared.implementation == nil else { return }
        CustomerIOReactNativeDeepLinkRouter.install()
    }

    /// Installs scene deep-link routing for the acknowledged JavaScript handler before the React
    /// Native bridge starts. Call this at the start of `scene(_:willConnectTo:options:)` when the
    /// host uses `CustomerIO.setDeepLinkHandler`.
    @objc
    public static func configureAcknowledgedSceneDeepLinkRouting() {
        // The cold scene connection happens before JavaScript can register its handler. Record the
        // host's ownership choice now so initialization cannot drain a buffered URL into Linking.
        guard CustomerIO.shared.implementation == nil else { return }
        CustomerIOReactNativeDeepLinkRouter.installAcknowledgedHandler()
    }

    /// Installs deep-link routing for an Expo-owned scene lifecycle.
    ///
    /// Expo forwards scene URLs into React Native Linking itself, including on React Native
    /// versions that do not expose the scene Linking selector used by the generic integration.
    @objc
    public static func configureExpoSceneDeepLinkRouting() {
        guard CustomerIO.shared.implementation == nil else { return }
        // Native initialization preserves an existing callback when its config does not provide one.
        CustomerIOReactNativeDeepLinkRouter.installForExpoSceneLifecycle()
    }

    /// Marks the React Native Linking listener as ready for buffered scene URLs.
    @objc
    func setDeepLinkRoutingReady() {
        CustomerIOReactNativeDeepLinkRouter.markReactNativeReady()
    }

    @objc
    public func setEventEmitter(_ emitter: AnyObject) {
        objcEventEmitter = emitter
    }

    @objc
    func registerDeepLinkHandler() {
        guard objcEventEmitter != nil else {
            logger.error("Customer.io could not register the React Native deep-link handler")
            return
        }

        deepLinkHandlerToken = CustomerIOReactNativeDeepLinkRouter.registerHandler { [weak self] id, url in
            self?.sendDeepLink(id: id, url: url)
        }
    }

    @objc
    func unregisterDeepLinkHandler() {
        guard let token = deepLinkHandlerToken else { return }
        CustomerIOReactNativeDeepLinkRouter.unregisterHandler(token)
        deepLinkHandlerToken = nil
    }

    @objc
    func acknowledgeDeepLink(_ id: String, handled: Bool) {
        CustomerIOReactNativeDeepLinkRouter.acknowledge(id, handled: handled)
    }

    @objc
    func invalidate() {
        unregisterDeepLinkHandler()
    }

    private func sendDeepLink(id: String, url: String) {
        guard let emitter = objcEventEmitter else { return }

        let selector = Selector(("emitOnDeepLinkReceived:"))
        guard emitter.responds(to: selector) else {
            logger.error("Customer.io could not emit a React Native deep-link event")
            return
        }
        _ = emitter.perform(selector, with: ["id": id, "url": url] as NSDictionary)
    }

    /// Ensures that the CustomerIO SDK is initialized before performing operations.
    /// Logs an error and returns false if the SDK is not initialized.
    private func ensureInitialized() -> Bool {
        guard isInitialized else {
            logger.error("CustomerIO SDK is not initialized. Please call initialize() first.")
            return false
        }
        return true
    }

    @objc
    func initialize(
        _ config: [String: Any],
        args: [String: Any],
        resolve: @escaping (RCTPromiseResolveBlock),
        reject: @escaping (RCTPromiseRejectBlock)
    ) {
        // Skip initialization if already initialized
        if isInitialized {
            logger.info("CustomerIO SDK is already initialized. Skipping initialization.")
            CustomerIOReactNativeDeepLinkRouter.markReactNativeReady()
            resolve(true)
            return
        }

        do {
            let packageSource = args["packageSource"] as? String
            let packageVersion = args["packageVersion"] as? String

            // Override SDK client info to include wrapper metadata in user agent
            if let source = packageSource, let sdkVersion = packageVersion {
                DIGraphShared.shared.override(
                    value: CustomerIOSdkClient(source: source, sdkVersion: sdkVersion),
                    forType: SdkClient.self
                )
            }

            let sdkConfigBuilder = try SDKConfigBuilder.create(from: config)

            let shouldInstallSceneRouter =
                CustomerIOReactNativeDeepLinkRouter.isSceneLifecycleEnabled ||
                (packageSource == "Expo" && CustomerIOReactNativeDeepLinkRouter.isExpoSceneLifecycleEnabled)
            if shouldInstallSceneRouter {
                _ = sdkConfigBuilder.deepLinkCallback { url in
                    CustomerIOReactNativeDeepLinkRouter.accept(url)
                    return true // React Native Linking cannot report handling; JavaScript owns fallback.
                }
            }

            #if CIO_LOCATION_ENABLED
            // Geofence implies location: register the location module whenever location
            // config is provided or geofence is enabled, since geofence relies on the
            // location module's fixes.
            #if CIO_GEOFENCE_ENABLED
            // Match NativeGeofence.module(from:): only a dictionary counts as configured,
            // so a non-map value (e.g. null bridged from JS) doesn't imply location.
            let geofenceConfigured = config["geofence"] as? [String: Any] != nil
            #else
            let geofenceConfigured = false
            #endif
            if let locationModule = NativeLocation.module(from: config, geofenceEnabled: geofenceConfigured) {
                _ = sdkConfigBuilder.addModule(locationModule)
            }
            #endif

            #if CIO_GEOFENCE_ENABLED
            // Geofence runs automatically once registered; relies on the location module above.
            if let geofenceModule = NativeGeofence.module(from: config) {
                _ = sdkConfigBuilder.addModule(geofenceModule)
            }
            #endif

            #if CIO_LIVEACTIVITIES_ENABLED
            if let liveActivitiesModule = NativeLiveActivities.module(from: config) {
                _ = sdkConfigBuilder.addModule(liveActivitiesModule)
            }
            #endif

            // Customer value wins; default on when the geofence module is added, off otherwise.
            #if CIO_GEOFENCE_ENABLED
            // Match NativeGeofence.module(from:): only a dictionary adds the module, so
            // background delivery shouldn't default on for a non-map geofence value.
            let geofenceAdded = config["geofence"] as? [String: Any] != nil
            #else
            let geofenceAdded = false
            #endif
            let allowBackgroundDelivery = (config["ios"] as? [String: Any])?["allowBackgroundDelivery"] as? Bool
            _ = sdkConfigBuilder.allowBackgroundDelivery(allowBackgroundDelivery ?? geofenceAdded)

            let builtConfig = sdkConfigBuilder.build()

            // Only CustomerIO.initialize must run on the main thread (e.g. for Location module).
            DispatchQueue.main.async { [weak self] in
                guard let self = self else {
                    reject(CustomerioConstants.cioTag, "Error initializing Customer.io SDK", nil)
                    return
                }
                CustomerIO.initialize(withConfig: builtConfig)

                do {
                    // Initialize in-app messaging if config provided
                    if let inAppConfig = try MessagingInAppConfigBuilder.build(from: config) {
                        MessagingInApp.initialize(withConfig: inAppConfig)
                        MessagingInApp.shared.setEventListener(ReactInAppEventListener.shared)
                    }
                } catch {
                    self.logger.error("[InApp] Failed to initialize module with error: \(error)")
                }

                self.logger.debug(
                    "Customer.io SDK (\(packageSource ?? "") \(packageVersion ?? "")) initialized with config: \(config)"
                )
                CustomerIOReactNativeDeepLinkRouter.markReactNativeReady()
                resolve(true)
            }
        } catch {
            logger.error("Initializing Customer.io SDK failed with error: \(error)")
            reject(CustomerioConstants.cioTag, "Error initializing Customer.io SDK", nil)
        }
    }

    @objc
    func identify(_ params: [String: Any]?) {
        guard ensureInitialized() else { return }

        let userId = params?["userId"] as? String
        let traits = params?["traits"] as? [String: Any]

        if let userId = userId {
            // Identify with userId and optional traits
            CustomerIO.shared.identify(userId: userId, traits: traits)
        } else if traits != nil {
            // Anonymous profile identification with traits only
            if let traitsJson = try? JSON(traits as Any) {
                CustomerIO.shared.identify(traits: traitsJson)
            } else {
                logger.error("Unable to parse traits to JSON: \(String(describing: traits))")
            }
        } else {
            logger.error("Provide id or traits to identify a user profile.")
        }
    }

    @objc
    func clearIdentify() {
        guard ensureInitialized() else { return }
        CustomerIO.shared.clearIdentify()
    }

    @objc
    func track(_ name: String, properties: [String: Any]?) {
        guard ensureInitialized() else { return }
        CustomerIO.shared.track(name: name, properties: properties)
    }

    @objc
    func screen(_ title: String, properties: [String: Any]?) {
        guard ensureInitialized() else { return }
        CustomerIO.shared.screen(title: title, properties: properties)
    }

    @objc
    func setProfileAttributes(_ attributes: [String: Any]) {
        guard ensureInitialized() else { return }
        CustomerIO.shared.setProfileAttributes(attributes)
    }

    @objc
    func setDeviceAttributes(_ attributes: [String: Any]) {
        guard ensureInitialized() else { return }
        CustomerIO.shared.setDeviceAttributes(attributes)
    }

    @objc
    func registerDeviceToken(_ token: String) {
        guard ensureInitialized() else { return }
        CustomerIO.shared.registerDeviceToken(token)
    }

    @objc
    func trackMetric(_ deliveryId: String, deviceToken: String, event: String) {
        guard ensureInitialized() else { return }
        guard let metricEvent = Metric.getEvent(from: event) else {
            logger.error("Invalid metric event: \(event)")
            return
        }

        CustomerIO.shared.trackMetric(deliveryID: deliveryId, event: metricEvent, deviceToken: deviceToken)
    }

    @objc
    func deleteDeviceToken() {
        guard ensureInitialized() else { return }
        CustomerIO.shared.deleteDeviceToken()
    }
}
