import CioAnalytics
import CioDataPipelines
import CioInternalCommon
import CioMessagingInApp

@objc(NativeCustomerIO)
public class NativeCustomerIO: NSObject {
    private let logger: CioInternalCommon.Logger = DIGraphShared.shared.logger
    /// Checks whether the CustomerIO SDK has been initialized.
    /// Returns `true` if the SDK has been successfully initialized, `false` otherwise.
    private var isInitialized: Bool { CustomerIO.shared.implementation != nil }

    /// Ensures that the CustomerIO SDK is initialized before performing operations.
    /// Logs an error and returns false if the SDK is not initialized.
    private func ensureInitialized() -> Bool {
        guard isInitialized else {
            logger.error("CustomerIO SDK is not initialized. Please call initialize() first.")
            return false
        }
        return true
    }

    @objc(isInitialized:reject:)
    func isInitialized(resolve: @escaping (RCTPromiseResolveBlock), _: @escaping (RCTPromiseRejectBlock)) {
        resolve(isInitialized)
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
            CustomerIO.initialize(withConfig: sdkConfigBuilder.build())

            do {
                // Initialize in-app messaging if config provided
                if let inAppConfig = try MessagingInAppConfigBuilder.build(from: config) {
                    MessagingInApp.initialize(withConfig: inAppConfig)
                    MessagingInApp.shared.setEventListener(ReactInAppEventListener.shared)
                }
            } catch {
                logger.error("[InApp] Failed to initialize module with error: \(error)")
            }
            logger.debug(
                "Customer.io SDK (\(packageSource ?? "") \(packageVersion ?? "")) initialized with config: \(config)"
            )
            resolve(true)
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
        CustomerIO.shared.profileAttributes = attributes
    }

    @objc
    func setDeviceAttributes(_ attributes: [String: Any]) {
        guard ensureInitialized() else { return }
        CustomerIO.shared.deviceAttributes = attributes
    }

    @objc
    func registerDeviceToken(_ token: String) {
        guard ensureInitialized() else { return }
        CustomerIO.shared.registerDeviceToken(token)
    }

    @objc
    func deleteDeviceToken() {
        guard ensureInitialized() else { return }
        CustomerIO.shared.deleteDeviceToken()
    }
}
