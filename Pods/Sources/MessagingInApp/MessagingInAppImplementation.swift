import CioInternalCommon
import CioTracking
import Foundation

class MessagingInAppImplementation: MessagingInAppInstance {
    private let siteId: String
    private let region: Region
    private let logger: CioInternalCommon.Logger
    private var queue: Queue
    private var jsonAdapter: JsonAdapter
    private var inAppProvider: InAppProvider
    private var profileStore: ProfileStore

    private var eventListener: InAppEventListener?
    private let threadUtil: ThreadUtil

    init(diGraph: DIGraph) {
        self.siteId = diGraph.sdkConfig.siteId
        self.region = diGraph.sdkConfig.region
        self.logger = diGraph.logger
        self.queue = diGraph.queue
        self.jsonAdapter = diGraph.jsonAdapter
        self.inAppProvider = diGraph.inAppProvider
        self.profileStore = diGraph.profileStore
        self.threadUtil = diGraph.threadUtil
    }

    func initialize() {
        inAppProvider.initialize(siteId: siteId, region: region, delegate: self)

        // if identifier is already present, set the userToken again so in case if the customer was already identified and
        // module was added later on, we can notify gist about it.
        if let identifier = profileStore.identifier {
            inAppProvider.setProfileIdentifier(identifier)
        }
    }

    func initialize(eventListener: InAppEventListener) {
        self.eventListener = eventListener
        initialize()
    }

    // Functions deprecated but need to exist for `MessagingInAppInstance` protocol.
    // Do not call these functions but non-deprecated ones.
    func initialize(organizationId: String) {}

    // Dismiss in-app message
    func dismissMessage() {
        inAppProvider.dismissMessage()
    }
}

extension MessagingInAppImplementation: ProfileIdentifyHook {
    public func beforeIdentifiedProfileChange(oldIdentifier: String, newIdentifier: String) {}

    public func profileIdentified(identifier: String) {
        logger.debug("registering profile \(identifier) for in-app")

        inAppProvider.setProfileIdentifier(identifier)
    }

    public func beforeProfileStoppedBeingIdentified(oldIdentifier: String) {
        logger.debug("removing profile for in-app")

        inAppProvider.clearIdentify()
    }
}

extension MessagingInAppImplementation: ScreenTrackingHook {
    public func screenViewed(name: String) {
        logger.debug("setting route for in-app to \(name)")

        // Gist expects webview to be launched in main thread and changing route will trigger locally stored in-app messages for that route.
        threadUtil.runMain {
            self.inAppProvider.setRoute(name)
        }
    }
}

extension MessagingInAppImplementation: GistDelegate {
    public func embedMessage(message: Message, elementId: String) {}

    // Aka: message opened
    public func messageShown(message: Message) {
        logger.debug("in-app message opened. \(message.describeForLogs)")

        eventListener?.messageShown(message: InAppMessage(gistMessage: message))

        if let deliveryId = getDeliveryId(from: message) {
            // the state of the SDK does not change if adding this queue task isn't successful so ignore result
            _ = queue.addTrackInAppDeliveryTask(deliveryId: deliveryId, event: .opened)
        }
    }

    public func messageDismissed(message: Message) {
        logger.debug("in-app message dismissed. \(message.describeForLogs)")

        eventListener?.messageDismissed(message: InAppMessage(gistMessage: message))
    }

    public func messageError(message: Message) {
        logger.error("error with in-app message. \(message.describeForLogs)")

        eventListener?.errorWithMessage(message: InAppMessage(gistMessage: message))
    }

    public func action(message: Message, currentRoute: String, action: String, name: String) {
        logger.debug("in-app action made. \(action), \(message.describeForLogs)")

        // a close action does not count as a clicked action.
        if action != "gist://close" {
            if let deliveryId = getDeliveryId(from: message) {
                // the state of the SDK does not change if adding this queue task isn't successful so ignore result
                _ = queue.addTrackInAppDeliveryTask(deliveryId: deliveryId, event: .clicked, metaData: ["action_name": name, "action_value": action])
            }
        }

        eventListener?.messageActionTaken(
            message: InAppMessage(gistMessage: message),
            actionValue: action,
            actionName: name
        )
    }

    private func getDeliveryId(from message: Message) -> String? {
        guard let deliveryId = message.gistProperties.campaignId else {
            return nil
        }

        return deliveryId
    }
}
