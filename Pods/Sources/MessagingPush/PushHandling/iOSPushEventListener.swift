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

        pushClickHandler.cleanupAfterPushInteractedWith(for: push)

        if pushAction.didClickOnPush {
            pushClickHandler.trackPushMetrics(for: push)
        }

        // Forward event to other push click handlers so they can receive a callback about this push event and optionally process the event.
        // This funcion is an async operation that calls code we do not own. Therefore, there is risk that the completion handler will not be called and the rest of our code will not be executed. That's why it's important that before we perform this call, we do as much push processing as we can to increase SDK reliability.
        pushEventHandlerProxy.onPushAction(pushAction, completionHandler: {
            // When this block of code executes, the customer is done processing the push event.

            // We do not open deep link until after customer is done processing the push event in case the deep link would leave the app.
            // We want to make sure the customer has a chance to process the push event before leaving the app.
            if pushAction.didClickOnPush {
                self.pushClickHandler.handleDeepLink(for: push)
            }

            // call the completion handler, indicating to the OS that we are done processing the push.
            completionHandler()
        })
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

        // Forward event to other push handlers so they can receive a callback about this push event.
        pushEventHandlerProxy.shouldDisplayPushAppInForeground(push, completionHandler: { _ in
            // When this block of code executes, the customer is done processing the push event.

            // Because push came from CIO, ignore the return result of other push handlers.
            // Determine if CIO push should be shown from SDK config
            let shouldShowPush = self.moduleConfig.showPushAppInForeground

            // The push came from CIO, so it gets handled by the CIO SDK.
            // Calling the completion handler indicates to the OS that we are done processing the push.
            completionHandler(shouldShowPush)
        })
    }
}
