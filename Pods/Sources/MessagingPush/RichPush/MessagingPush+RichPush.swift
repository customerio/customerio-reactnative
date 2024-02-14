import CioInternalCommon
import CioTracking
import Foundation
#if canImport(UserNotifications) && canImport(UIKit)
import UIKit
import UserNotifications
#endif

public extension MessagingPush {
    #if canImport(UserNotifications)
    /**
     - returns:
     Bool indicating if this push notification is one handled by Customer.io SDK or not.
     If function returns `false`, `contentHandler` will *not* be called by the SDK.
     */
    @discardableResult
    func didReceive(
        _ request: UNNotificationRequest,
        withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void
    ) -> Bool {
        guard let implementation = implementation else {
            contentHandler(request.content)
            return false
        }

        return implementation.didReceive(request, withContentHandler: contentHandler)
    }

    /**
     iOS telling the notification service to hurry up and stop modifying the push notifications.
     Stop all network requests and modifying and show the push for what it looks like now.
     */
    func serviceExtensionTimeWillExpire() {
        implementation?.serviceExtensionTimeWillExpire()
    }
    #endif
}

extension MessagingPushImplementation {
    #if canImport(UserNotifications)
    /**
     - returns:
     Bool indicating if this push notification is one handled by Customer.io SDK or not.
     If function returns `false`, `contentHandler` will *not* be called by the SDK.
     */
    @discardableResult
    func didReceive(
        _ request: UNNotificationRequest,
        withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void
    ) -> Bool {
        logger.info("did receive notification request. Checking if message was a push sent from Customer.io...")
        logger.debug("notification request: \(request.content.userInfo)")

        let push = UNNotificationWrapper(notificationRequest: request)

        guard let pushCioDeliveryInfo = push.cioDelivery else {
            logger.info("the notification was not sent by Customer.io. Ignoring notification request.")
            return false
        }

        logger.info("push was sent from Customer.io. Processing the request...")

        if sdkConfig.autoTrackPushEvents {
            logger.info("automatically tracking push metric: delivered")
            logger.debug("parsed deliveryId \(pushCioDeliveryInfo.id), deviceToken: \(pushCioDeliveryInfo.token)")

            trackMetric(deliveryID: pushCioDeliveryInfo.id, event: .delivered, deviceToken: pushCioDeliveryInfo.token)
        }

        RichPushRequestHandler.shared.startRequest(
            push: push
        ) { composedRichPush in
            self.logger.debug("rich push was composed \(composedRichPush).")

            // This conditional will only work in production and not in automated tests. But this file cannot be in automated tests so this conditional is OK for now.
            if let composedRichPush = composedRichPush as? UNNotificationWrapper {
                self.finishTasksThenReturn(contentHandler: contentHandler, notificationContent: composedRichPush.notificationContent)
            }
        }

        return true
    }

    private func finishTasksThenReturn(
        contentHandler: @escaping (UNNotificationContent) -> Void,
        notificationContent: UNNotificationContent
    ) {
        logger
            .debug(
                "running all background queue tasks and waiting until complete to prevent OS from killing notification service extension before all HTTP requests have been performed"
            )
        backgroundQueue.run {
            self.logger.debug("all background queue tasks done running.")
            self.logger.info("Customer.io push processing is done!")

            contentHandler(notificationContent)
        }
    }

    /**
     iOS telling the notification service to hurry up and stop modifying the push notifications.
     Stop all network requests and modifying and show the push for what it looks like now.
     */
    func serviceExtensionTimeWillExpire() {
        logger.info("notification service time will expire. Stopping all notification requests early.")

        RichPushRequestHandler.shared.stopAll()
    }
    #endif
}
