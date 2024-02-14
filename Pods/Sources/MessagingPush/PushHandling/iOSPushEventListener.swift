import CioInternalCommon
import CioTracking
import Foundation

@available(iOSApplicationExtension, unavailable)
// sourcery: InjectRegister = "PushEventHandler"
class IOSPushEventListener: PushEventHandler {
    private let jsonAdapter: JsonAdapter
    private var pushEventHandlerProxy: PushEventHandlerProxy
    private let moduleConfig: MessagingPushConfigOptions
    private let pushClickHandler: PushClickHandler
    private let pushHistory: PushHistory
    private let logger: Logger

    init(jsonAdapter: JsonAdapter, pushEventHandlerProxy: PushEventHandlerProxy, moduleConfig: MessagingPushConfigOptions, pushClickHandler: PushClickHandler, pushHistory: PushHistory, logger: Logger) {
        self.jsonAdapter = jsonAdapter
        self.pushEventHandlerProxy = pushEventHandlerProxy
        self.moduleConfig = moduleConfig
        self.pushClickHandler = pushClickHandler
        self.pushHistory = pushHistory
        self.logger = logger
    }

    func onPushAction(_ pushAction: PushNotificationAction, completionHandler: @escaping () -> Void) {
        guard let dateWhenPushDelivered = pushAction.push.deliveryDate else {
            return
        }
        let push = pushAction.push
        logger.debug("On push action event. push action: \(pushAction))")

        guard !pushHistory.hasHandledPush(pushEvent: .didReceive, pushId: push.pushId, pushDeliveryDate: dateWhenPushDelivered) else {
            // push has already been handled. exit early
            return
        }

        guard push.isPushSentFromCio else {
            // Do not call completionHandler() because push did not come from CIO.
            // Forward the request to all other push click handlers in app to give them a chance to handle it.

            pushEventHandlerProxy.onPushAction(pushAction, completionHandler: completionHandler)

            return
        }

        logger.debug("Push came from CIO. Handle the didReceive event on behalf of the customer.")

        if pushAction.didClickOnPush {
            pushClickHandler.pushClicked(push)
        }

        // call the completion handler so the customer does not need to.
        completionHandler()
    }

    func shouldDisplayPushAppInForeground(_ push: PushNotification, completionHandler: @escaping (Bool) -> Void) {
        guard let dateWhenPushDelivered = push.deliveryDate else {
            return
        }
        logger.debug("Push event: willPresent. push: \(push)")

        guard !pushHistory.hasHandledPush(pushEvent: .willPresent, pushId: push.pushId, pushDeliveryDate: dateWhenPushDelivered) else {
            // push has already been handled. exit early

            // See notes in didReceive function to learn more about this logic of exiting early when we already have handled a push.
            return
        }

        guard push.isPushSentFromCio else {
            // Do not call completionHandler() because push did not come from CIO.
            // Forward the request to all other push click handlers in app to give them a chance to handle it.

            pushEventHandlerProxy.shouldDisplayPushAppInForeground(push, completionHandler: completionHandler)

            return
        }

        logger.debug("Push came from CIO. Handle the willPresent event on behalf of the customer.")

        let shouldShowPush = moduleConfig.showPushAppInForeground

        // Call the completionHandler so customer does not need to. The push came from CIO, so it gets handled by the CIO SDK.
        completionHandler(shouldShowPush)
    }
}
