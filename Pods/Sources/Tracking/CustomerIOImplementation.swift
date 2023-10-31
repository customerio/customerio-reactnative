import CioInternalCommon
import Foundation

/**
 Because of `CustomerIO.shared` being a singleton API, there is always a use-case
 of calling any of the public functions on `CustomerIO` class *before* the SDK has
 been initialized. To make this use case easy to handle, we separate the logic of
 the CustomerIO class into this class. Therefore, it's assumed that as long as
 there is an instance of `CustomerIOImplementation` present, the SDK has been
 initialized successfully.
 */
class CustomerIOImplementation: CustomerIOInstance {
    public var siteId: String? {
        sdkConfig.siteId
    }

    private let backgroundQueue: Queue
    private let jsonAdapter: JsonAdapter
    private var profileStore: ProfileStore
    private var hooks: HooksManager
    private let logger: Logger
    private var globalDataStore: GlobalDataStore
    private let sdkConfig: SdkConfig
    private let deviceAttributesProvider: DeviceAttributesProvider
    private let dateUtil: DateUtil
    private let deviceInfo: DeviceInfo

    static var autoScreenViewBody: (() -> [String: Any])?

    /**
     Constructor for singleton, only.

     Try loading the credentials previously saved for the singleton instance.
     */
    init(diGraph: DIGraph) {
        self.backgroundQueue = diGraph.queue
        self.jsonAdapter = diGraph.jsonAdapter
        self.profileStore = diGraph.profileStore
        self.hooks = diGraph.hooksManager
        self.logger = diGraph.logger
        self.globalDataStore = diGraph.globalDataStore
        self.sdkConfig = diGraph.sdkConfig
        self.deviceAttributesProvider = diGraph.deviceAttributesProvider
        self.dateUtil = diGraph.dateUtil
        self.deviceInfo = diGraph.deviceInfo
    }

    public var config: SdkConfig? {
        sdkConfig
    }

    public var profileAttributes: [String: Any] {
        get {
            [:]
        }
        set {
            guard let existingProfileIdentifier = profileStore.identifier else {
                return
            }
            identify(identifier: existingProfileIdentifier, body: newValue)
        }
    }

    public var deviceAttributes: [String: Any] {
        get {
            [:]
        }
        set {
            guard let deviceToken = globalDataStore.pushDeviceToken else { return }
            let attributes = newValue
            addDeviceAttributes(deviceToken: deviceToken, customAttributes: attributes)
        }
    }

    // this function could use a refactor. It's long and complex. Our automated tests are what keeps us feeling
    // confident in the code, but the code here is difficult to maintain.
    // swiftlint:disable:next function_body_length
    public func identify<RequestBody: Encodable>(
        identifier: String,
        body: RequestBody
    ) {
        if identifier.isBlankOrEmpty() {
            logger.error("profile cannot be identified: Identifier is empty. Please retry with a valid, non-empty identifier.")
            return
        }
        logger.info("identify profile \(identifier)")

        let currentlyIdentifiedProfileIdentifier = profileStore.identifier
        let isChangingIdentifiedProfile = currentlyIdentifiedProfileIdentifier != nil &&
            currentlyIdentifiedProfileIdentifier != identifier
        let isFirstTimeIdentifying = currentlyIdentifiedProfileIdentifier == nil

        if let currentlyIdentifiedProfileIdentifier = currentlyIdentifiedProfileIdentifier,
           isChangingIdentifiedProfile {
            logger.info("changing profile from id \(currentlyIdentifiedProfileIdentifier) to \(identifier)")

            logger
                .debug(
                    "deleting token from previously identified profile to prevent sending messages to it. It's assumed that for privacy and messaging relevance, you only want to send messages to devices that a profile is currently identifed with."
                )
            deleteDeviceToken()

            logger.debug("running hooks changing profile from \(currentlyIdentifiedProfileIdentifier) to \(identifier)")
            hooks.profileIdentifyHooks.forEach { hook in
                hook.beforeIdentifiedProfileChange(
                    oldIdentifier: currentlyIdentifiedProfileIdentifier,
                    newIdentifier: identifier
                )
            }
        }

        let jsonBodyString = jsonAdapter.toJsonString(body)
        logger.debug("identify profile attributes \(jsonBodyString ?? "none")")

        let queueTaskData = IdentifyProfileQueueTaskData(
            identifier: identifier,
            attributesJsonString: jsonBodyString
        )

        // If SDK previously identified profile X and X is being identified again, no use blocking the queue
        // with a queue group.
        var queueGroupStart: QueueTaskGroup? = .identifiedProfile(identifier: identifier)
        if !isChangingIdentifiedProfile {
            queueGroupStart = nil
        }

        let queueStatus = backgroundQueue.addTask(
            type: QueueTaskType.identifyProfile.rawValue,
            data: queueTaskData,
            groupStart: queueGroupStart
        )

        // don't modify the state of the SDK until we confirm we added a background queue task successfully.
        // XXX: better handle scenario when adding task to queue is not successful
        guard queueStatus.success else {
            // XXX: better handle scenario when adding task to queue is not successful
            logger.debug("failed to enqueue identify task")
            return
        }

        logger.debug("storing identifier on device storage \(identifier)")
        profileStore.identifier = identifier

        if isFirstTimeIdentifying || isChangingIdentifiedProfile {
            if let existingDeviceToken = globalDataStore.pushDeviceToken {
                logger.debug("registering existing device token to newly identified profile: \(identifier)")
                // this code assumes that the newly identified profile has been saved to device storage. only call this
                // function until after the SDK stores the new profile identifier
                registerDeviceToken(existingDeviceToken)
            }

            logger.debug("running hooks profile identified \(identifier)")
            hooks.profileIdentifyHooks.forEach { hook in
                hook.profileIdentified(identifier: identifier)
            }
        }
    }

    public func identify(identifier: String, body: [String: Any]) {
        identify(identifier: identifier, body: StringAnyEncodable(logger: logger, body))
    }

    public func clearIdentify() {
        logger.info("clearing identified profile")

        guard let currentlyIdentifiedProfileIdentifier = profileStore.identifier else {
            return
        }

        logger
            .debug(
                "delete device token from \(currentlyIdentifiedProfileIdentifier) to stop sending push to a profile that is no longer identified"
            )
        deleteDeviceToken()

        logger.debug("running hooks: profile stopped being identified \(currentlyIdentifiedProfileIdentifier)")
        hooks.profileIdentifyHooks.forEach { hook in
            hook.beforeProfileStoppedBeingIdentified(oldIdentifier: currentlyIdentifiedProfileIdentifier)
        }

        logger.debug("deleting profile info from device storage")
        // remove device identifier from storage last so hooks can succeed.
        profileStore.identifier = nil
    }

    public func track<RequestBody: Encodable>(
        name: String,
        data: RequestBody?
    ) {
        _ = trackEvent(type: .event, name: name, data: data)
    }

    public func track(name: String, data: [String: Any]) {
        track(name: name, data: StringAnyEncodable(logger: logger, data))
    }

    public func screen(name: String, data: [String: Any]) {
        screen(name: name, data: StringAnyEncodable(logger: logger, data))
    }

    public func screen<RequestBody: Encodable>(
        name: String,
        data: RequestBody
    ) {
        let eventWasTracked = trackEvent(type: .screen, name: name, data: data)

        if eventWasTracked {
            hooks.screenViewHooks.forEach { hook in
                hook.screenViewed(name: name)
            }
        }
    }

    /**
     Register a new device token with Customer.io, associated with the current active customer. If there
     is no active customer, this will fail to register the device
     */
    public func registerDeviceToken(_ deviceToken: String) {
        addDeviceAttributes(deviceToken: deviceToken)
    }

    /**
     Adds device default and custom attributes and registers device token.
     */
    private func addDeviceAttributes(deviceToken: String, customAttributes: [String: Any] = [:]) {
        logger.info("registering device token \(deviceToken)")
        logger.debug("storing device token to device storage \(deviceToken)")
        // no matter what, save the device token for use later. if a customer is identified later,
        // we can reference the token and register it to a new profile.
        globalDataStore.pushDeviceToken = deviceToken

        guard let identifier = profileStore.identifier else {
            logger.info("no profile identified, so not registering device token to a profile")
            return
        }
        if identifier.isBlankOrEmpty() {
            logger.error("profile cannot be identified: Identifier is empty, so not registering device token to a profile")
            return
        }

        // OS name might not be available if running on non-apple product. We currently only support iOS for the SDK
        // and iOS should always be non-nil. Though, we are consolidating all Apple platforms under iOS but this check
        // is
        // required to prevent SDK execution for unsupported OS.
        if deviceInfo.osName == nil {
            logger.info("SDK being executed from unsupported OS. Ignoring request to register push token.")
            return
        }
        // Consolidate all Apple platforms under iOS
        let deviceOsName = "iOS"
        deviceAttributesProvider.getDefaultDeviceAttributes { defaultDeviceAttributes in
            let deviceAttributes = defaultDeviceAttributes.mergeWith(customAttributes)

            let encodableBody = StringAnyEncodable(logger: self.logger, deviceAttributes) // makes [String: Any] Encodable to use in JSON body.
            let requestBody = RegisterDeviceRequest(device: Device(
                token: deviceToken,
                platform: deviceOsName,
                lastUsed: self.dateUtil.now,
                attributes: encodableBody
            ))

            guard let jsonBodyString = self.jsonAdapter.toJsonString(requestBody) else {
                return
            }
            let queueTaskData = RegisterPushNotificationQueueTaskData(
                profileIdentifier: identifier,
                attributesJsonString: jsonBodyString
            )

            _ = self.backgroundQueue.addTask(
                type: QueueTaskType.registerPushToken.rawValue,
                data: queueTaskData,
                groupStart: .registeredPushToken(token: deviceToken),
                blockingGroups: [.identifiedProfile(identifier: identifier)]
            )
        }
    }

    /**
     Delete the currently registered device token
     */
    public func deleteDeviceToken() {
        logger.info("deleting device token request made")

        guard let existingDeviceToken = globalDataStore.pushDeviceToken else {
            logger.info("no device token exists so ignoring request to delete")
            return // no device token to delete, ignore request
        }
        // Do not delete push token from device storage. The token is valid
        // once given to SDK. We need it for future profile identifications.

        guard let identifiedProfileId = profileStore.identifier else {
            logger.info("no profile identified so not removing device token from profile")
            return // no profile to delete token from, ignore request
        }

        _ = backgroundQueue.addTask(
            type: QueueTaskType.deletePushToken.rawValue,
            data: DeletePushNotificationQueueTaskData(
                profileIdentifier: identifiedProfileId,
                deviceToken: existingDeviceToken
            ),
            blockingGroups: [
                .registeredPushToken(token: existingDeviceToken),
                .identifiedProfile(identifier: identifiedProfileId)
            ]
        )
    }

    /**
     Track a push metric
     */
    public func trackMetric(
        deliveryID: String,
        event: Metric,
        deviceToken: String
    ) {
        logger.info("push metric \(event.rawValue)")

        logger.debug("delivery id \(deliveryID) device token \(deviceToken)")

        _ = backgroundQueue.addTask(
            type: QueueTaskType.trackPushMetric.rawValue,
            data: MetricRequest(
                deliveryId: deliveryID,
                event: event,
                deviceToken: deviceToken,
                timestamp: Date()
            )
        )
    }
}

extension CustomerIOImplementation {
    // returns if an event was tracked. If no event was tracked (request was ignored), false will be returned.
    private func trackEvent<RequestBody: Encodable>(
        type: EventType,
        name: String,
        data: RequestBody?
    ) -> Bool {
        let eventTypeDescription = (type == .screen) ? "track screen view event" : "track event"

        logger.info("\(eventTypeDescription) \(name)")

        guard let currentlyIdentifiedProfileIdentifier = profileStore.identifier else {
            // XXX: when we have anonymous profiles in SDK,
            // we can decide to not ignore events when a profile is not logged yet.
            logger.info("ignoring \(eventTypeDescription) \(name) because no profile currently identified")
            return false
        }

        // JSON encoding with `data = nil` returns `"data":null`.
        // API returns 400 "event data must be a hash" for that. `"data":{}` is a better default.
        let data: AnyEncodable = (data == nil) ? AnyEncodable(EmptyRequestBody()) : AnyEncodable(data)

        let requestBody = TrackRequestBody(type: type, name: name, data: data, timestamp: dateUtil.now)
        guard let jsonBodyString = jsonAdapter.toJsonString(requestBody) else {
            logger.error("attributes provided for \(eventTypeDescription) \(name) failed to JSON encode.")
            return false
        }
        logger.debug("\(eventTypeDescription) attributes \(jsonBodyString)")

        let queueData = TrackEventQueueTaskData(
            identifier: currentlyIdentifiedProfileIdentifier,
            attributesJsonString: jsonBodyString
        )

        // XXX: better handle scenario when adding task to queue is not successful
        _ = backgroundQueue.addTask(
            type: QueueTaskType.trackEvent.rawValue,
            data: queueData,
            blockingGroups: [
                .identifiedProfile(identifier: currentlyIdentifiedProfileIdentifier)
            ]
        )

        return true
    }
}
