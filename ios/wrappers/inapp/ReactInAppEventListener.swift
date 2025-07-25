import CioMessagingInApp

/**
 * React Native bridge for Customer.io in-app messaging events.
 * Converts native SDK events to JavaScript compatible format.
 */
class ReactInAppEventListener: InAppEventListener {
    // Shared instance for global access
    static let shared = ReactInAppEventListener()
    // Event emitter function to send events to React Native layer
    private var eventEmitter: (([String: Any?]) -> Void)?

    // Sets the event emitter function
    func setEventEmitter(_ emitter: (([String: Any?]) -> Void)?) {
        eventEmitter = emitter
    }

    // Clears the event emitter to prevent memory leaks
    func clearEventEmitter() {
        eventEmitter = nil
    }

    // Emits an in-app message event to React Native with unified event structure
    private func emitInAppEvent(
        eventType: String,
        message: InAppMessage,
        actionValue: String? = nil,
        actionName: String? = nil
    ) {
        var data: [String: Any?] = [
            CustomerioConstants.eventType: eventType,
            CustomerioConstants.messageId: message.messageId,
            CustomerioConstants.deliveryId: message.deliveryId
        ]

        if let actionValue = actionValue {
            data[CustomerioConstants.actionValue] = actionValue
        }
        if let actionName = actionName {
            data[CustomerioConstants.actionName] = actionName
        }

        eventEmitter?(data)
    }

    public func messageShown(message: InAppMessage) {
        emitInAppEvent(eventType: CustomerioConstants.messageShown, message: message)
    }

    public func messageDismissed(message: InAppMessage) {
        emitInAppEvent(eventType: CustomerioConstants.messageDismissed, message: message)
    }

    public func errorWithMessage(message: InAppMessage) {
        emitInAppEvent(eventType: CustomerioConstants.errorWithMessage, message: message)
    }

    public func messageActionTaken(message: InAppMessage, actionValue: String, actionName: String) {
        emitInAppEvent(
            eventType: CustomerioConstants.messageActionTaken,
            message: message,
            actionValue: actionValue,
            actionName: actionName
        )
    }
}
