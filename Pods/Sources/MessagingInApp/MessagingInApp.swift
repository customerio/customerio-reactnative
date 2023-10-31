import CioInternalCommon
import CioTracking
import Foundation

public protocol MessagingInAppInstance: AutoMockable {
    // sourcery:Name=initialize
    func initialize()
    // sourcery:Name=initializeEventListener
    func initialize(eventListener: InAppEventListener)

    @available(*, deprecated, message: "Parameter organizationId no longer being used. Remove the parameter from your function call to migrate to new function.")
    // sourcery:Name=initializeOrganizationId
    func initialize(organizationId: String)

    func dismissMessage()
}

public class MessagingInApp: ModuleTopLevelObject<MessagingInAppInstance>, MessagingInAppInstance {
    @Atomic public internal(set) static var shared = MessagingInApp()

    // constructor that is called by test classes
    // This function's job is to populate the `shared` property with
    // overrides such as DI graph.
    override init(implementation: MessagingInAppInstance?, sdkInitializedUtil: SdkInitializedUtil) {
        super.init(implementation: implementation, sdkInitializedUtil: sdkInitializedUtil)
    }

    // constructor used in production with default DI graph
    // singleton constructor
    override private init() {
        super.init()
    }

    // for testing
    static func resetSharedInstance() {
        shared = MessagingInApp()
    }

    // MARK: static initialized functions for customers.

    // static functions are identical to initialize functions in InAppInstance protocol to try and make a more convenient
    // API for customers. Customers can use `MessagingInApp.initialize(...)` instead of `MessagingInApp.shared.initialize(...)`.
    // Trying to follow the same API as `CustomerIO` class with `initialize()`.

    // Initialize SDK module
    public static func initialize() {
        shared.initialize()
    }

    public static func initialize(eventListener: InAppEventListener) {
        shared.initialize(eventListener: eventListener)
    }

    @available(*, deprecated, message: "Parameter organizationId no longer being used. Remove the parameter from your function call to migrate to new function.")
    public static func initialize(organizationId: String) {
        shared.initialize(organizationId: organizationId)
    }

    // MARK: initialize functions to initialize module.

    // Multiple initialize functions to inherit the InAppInstance protocol which contains multiple initialize functions.

    public func initialize() {
        commonInitialize(eventListener: nil)
    }

    public func initialize(eventListener: InAppEventListener) {
        commonInitialize(eventListener: eventListener)
    }

    @available(*, deprecated, message: "Parameter organizationId no longer being used. Remove the parameter from your function call to migrate to new function.")
    public func initialize(organizationId: String) {
        commonInitialize(eventListener: nil)
    }

    private func commonInitialize(eventListener: InAppEventListener?) {
        guard let implementation = implementation else {
            sdkNotInitializedAlert("CustomerIO class has not yet been initialized. Request to initialize the in-app module has been ignored.")
            return
        }

        initializeModuleIfSdkInitialized()

        if let eventListener = eventListener {
            implementation.initialize(eventListener: eventListener)
        } else {
            implementation.initialize()
        }
    }

    override public func inititlizeModule(diGraph: DIGraph) {
        let logger = diGraph.logger
        logger.debug("Setting up in-app module...")

        // Register MessagingPush module hooks now that the module is being initialized.
        let hooks = diGraph.hooksManager
        let moduleHookProvider = MessagingInAppModuleHookProvider()
        hooks.add(key: .messagingInApp, provider: moduleHookProvider)

        logger.info("In-app module setup with SDK")
    }

    override public func getImplementationInstance(diGraph: DIGraph) -> MessagingInAppInstance {
        MessagingInAppImplementation(diGraph: diGraph)
    }

    // Dismiss in-app message
    public func dismissMessage() {
        implementation?.dismissMessage()
    }
}
