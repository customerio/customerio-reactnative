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

        guard let deliveryID: String = request.content.userInfo["CIO-Delivery-ID"] as? String,
              let deviceToken: String = request.content.userInfo["CIO-Delivery-Token"] as? String
        else {
            logger.info("the notification was not sent by Customer.io. Ignoring notification request.")
            return false
        }

        logger.info("push was sent from Customer.io. Processing the request...")

        if sdkConfig.autoTrackPushEvents {
            logger.info("automatically tracking push metric: delivered")
            logger.debug("parsed deliveryId \(deliveryID), deviceToken: \(deviceToken)")

            trackMetric(deliveryID: deliveryID, event: .delivered, deviceToken: deviceToken)
        }

        if let richPushContent = CustomerIOParsedPushPayload.parse(
            notificationContent: request.content,
            jsonAdapter: jsonAdapter
        ) {
            logger
                .info("""
                Parsing notification request to display rich content such as images, deep links, etc.
                """)
            logger.debug("push content: \(richPushContent)")

            RichPushRequestHandler.shared.startRequest(
                request,
                content: richPushContent
            ) { notificationContent in
                self.logger.debug("rich push was composed \(notificationContent).")

                self.finishTasksThenReturn(contentHandler: contentHandler, notificationContent: notificationContent)
            }
        } else {
            logger.info("the push was a simple push, not a rich push. Processing is complete.")

            finishTasksThenReturn(contentHandler: contentHandler, notificationContent: request.content)
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
