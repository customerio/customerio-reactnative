import CioInternalCommon
import CioTracking
import Foundation
import UserNotifications

@available(iOSApplicationExtension, unavailable)
protocol PushClickHandler: AutoMockable {
    // Cleanup files on device that were used when the push was displayed. Files are no longer
    // needed now that the push is no longer shown.
    func cleanupAfterPushInteractedWith(for push: PushNotification)
    func trackPushMetrics(for push: PushNotification)
    func handleDeepLink(for push: PushNotification)
}

@available(iOSApplicationExtension, unavailable)
// sourcery: InjectRegister = "PushClickHandler"
class PushClickHandlerImpl: PushClickHandler {
    private let deepLinkUtil: DeepLinkUtil
    private let customerIO: CustomerIOInstance

    init(deepLinkUtil: DeepLinkUtil, customerIO: CustomerIOInstance) {
        self.deepLinkUtil = deepLinkUtil
        self.customerIO = customerIO
    }

    func trackPushMetrics(for push: PushNotification) {
        guard let cioDelivery = push.cioDelivery else {
            return
        }

        customerIO.trackMetric(deliveryID: cioDelivery.id, event: .opened, deviceToken: cioDelivery.token)
    }

    func handleDeepLink(for push: PushNotification) {
        if let deepLinkUrl = push.cioDeepLink?.url {
            deepLinkUtil.handleDeepLink(deepLinkUrl)
        }
    }

    // There are files that are created just for displaying a rich push. After a push is interacted with, those files
    // are no longer needed.
    // This function's job is to cleanup after a push is no longer being displayed.
    func cleanupAfterPushInteractedWith(for push: PushNotification) {
        push.cioAttachments.forEach { attachment in
            let localFilePath = attachment.localFileUrl

            try? FileManager.default.removeItem(at: localFilePath)
        }
    }
}
