import CioInternalCommon
import CioTracking
import Foundation

/**
 Swift code goes into this module that are common to *all* of the Messaging Push modules (APN, FCM, etc).
 So, performing an HTTP request to the API with a device token goes here.
  */
public class MessagingPush: ModuleTopLevelObject<MessagingPushInstance>, MessagingPushInstance {
    @Atomic public private(set) static var shared = MessagingPush()
    private var globalDataStore: GlobalDataStore

    /*
     It's preferred to get a lock from lockmanager. Because this is a top-level class where the digraph may be nil, it's more difficult to get a lock from lockmanager.

     Because this class is a singleton, we can create a lock instance that will be shared in all calls to this class.
     */
    private let lock = Lock.unsafeInit()
    @Atomic private var hasSetupModule = false

    // singleton instance of module configuration
    @Atomic public var moduleConfig: MessagingPushConfigOptions = .init()

    // testing constructor
    init(implementation: MessagingPushInstance?, globalDataStore: GlobalDataStore, sdkInitializedUtil: SdkInitializedUtil) {
        self.globalDataStore = globalDataStore
        super.init(implementation: implementation, sdkInitializedUtil: sdkInitializedUtil)
    }

    // singleton constructor
    override private init() {
        self.globalDataStore = CioGlobalDataStore.getInstance()
        super.init()
    }

    // for testing
    static func resetSharedInstance() {
        shared = MessagingPush()
    }

    // Gets called when MessagingPushAPN.initialize() or MessagingPushFCM.initialize() called.
    @available(iOSApplicationExtension, unavailable)
    public static func initialize(config: MessagingPushConfigOptions? = nil) {
        if let newConfig = config {
            shared.moduleConfig = newConfig
        }

        MessagingPush.shared.initializeModuleIfSdkInitialized()
    }

    // Note: Make sure this function is only called 1 time. Module configuration can be modified at runtime, but the setup logic in this function that sets up logic such as listeners should only be called 1 time.
    @available(iOSApplicationExtension, unavailable)
    override public func inititlizeModule(diGraph: DIGraph) {
        // Make this function thread-safe by immediately locking it.
        lock.lock()
        defer {
            lock.unlock()
        }

        // Make sure this function is only called 1 time.
        if hasSetupModule {
            return
        }
        hasSetupModule = true

        let logger = diGraph.logger
        logger.debug("Setting up MessagingPush module...")

        if diGraph.sdkConfig.autoTrackPushEvents {
            diGraph.automaticPushClickHandling.start()
        }

        logger.info("MessagingPush module setup with SDK")
    }

    override public func getImplementationInstance(diGraph: DIGraph) -> MessagingPushInstance {
        MessagingPushImplementation(diGraph: diGraph)
    }

    /**
     Register a new device token with Customer.io, associated with the current active customer. If there
     is no active customer, this will fail to register the device
     */
    public func registerDeviceToken(_ deviceToken: String) {
        // Compare the new deviceToken with the one stored in globalDataStore.
        // If they are different, proceed with registering the device token.
        // This check helps to avoid duplicate requests, as registerDeviceToken is already called on SDK initialization.
        if deviceToken != globalDataStore.pushDeviceToken {
            // Call the registerDeviceToken method on the implementation.
            // This method is responsible for registering the device token and updating the globalDataStore as well.
            if let implementation = implementation {
                implementation.registerDeviceToken(deviceToken)
            } else {
                // Update the globalDataStore with the new device token.
                // The implementation may be nil due to lifecycle issues in wrappers SDKs.
                globalDataStore.pushDeviceToken = deviceToken
            }
        }
    }

    /**
     Delete the currently registered device token
     */
    public func deleteDeviceToken() {
        implementation?.deleteDeviceToken()
    }

    /**
        Track a push metric
     */
    public func trackMetric(
        deliveryID: String,
        event: Metric,
        deviceToken: String
    ) {
        implementation?.trackMetric(deliveryID: deliveryID, event: event, deviceToken: deviceToken)
    }
}
