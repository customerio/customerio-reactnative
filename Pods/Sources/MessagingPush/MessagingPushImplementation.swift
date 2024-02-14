import CioInternalCommon
import CioTracking
import Foundation

class MessagingPushImplementation: MessagingPushInstance {
    let siteId: String
    let logger: Logger
    let jsonAdapter: JsonAdapter
    let sdkConfig: SdkConfig
    let backgroundQueue: Queue
    let sdkInitializedUtil: SdkInitializedUtil

    private var customerIO: CustomerIO? {
        sdkInitializedUtil.customerio
    }

    /// testing init
    init(
        logger: Logger,
        jsonAdapter: JsonAdapter,
        sdkConfig: SdkConfig,
        backgroundQueue: Queue,
        sdkInitializedUtil: SdkInitializedUtil
    ) {
        self.siteId = sdkConfig.siteId
        self.logger = logger
        self.jsonAdapter = jsonAdapter
        self.sdkConfig = sdkConfig
        self.backgroundQueue = backgroundQueue
        self.sdkInitializedUtil = sdkInitializedUtil
    }

    init(diGraph: DIGraph) {
        self.siteId = diGraph.sdkConfig.siteId
        self.logger = diGraph.logger
        self.jsonAdapter = diGraph.jsonAdapter
        self.sdkConfig = diGraph.sdkConfig
        self.backgroundQueue = diGraph.queue
        self.sdkInitializedUtil = SdkInitializedUtilImpl()
    }

    func deleteDeviceToken() {
        customerIO?.deleteDeviceToken()
    }

    func registerDeviceToken(_ deviceToken: String) {
        customerIO?.registerDeviceToken(deviceToken)
    }

    func trackMetric(deliveryID: String, event: Metric, deviceToken: String) {
        customerIO?.trackMetric(deliveryID: deliveryID, event: event, deviceToken: deviceToken)
    }
}
