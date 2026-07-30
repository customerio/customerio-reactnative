import CioInternalCommon
import CioMessagingInApp

/**
 * React Native bridge for Customer.io Visual Notification Inbox events.
 *
 * Registered on the SDK (via `MessagingInApp.shared.setInboxEventListener`) only while a JS listener
 * is registered. Because the New-Arch event emitter is one-way we cannot round-trip a bool back from
 * JS, so `messageActionTaken` forwards the event fire-and-forget and RETURNS `true` — telling the SDK
 * the host handled the action so the SDK suppresses its default navigation. The JS host owns action
 * handling while a listener is registered. Observational callbacks forward fire-and-forget.
 */
public class ReactInboxEventListener: InboxEventListener {
    // Shared instance for global access
    public static let shared = ReactInboxEventListener()

    private init() {}

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

    // Emits an inbox message event to React Native with a serialized message payload
    private func emitInboxEvent(
        eventType: String,
        message: InboxMessage,
        actionName: String? = nil,
        actionValue: String? = nil
    ) {
        var data: [String: Any?] = [
            CustomerioConstants.eventType: eventType,
            CustomerioConstants.inboxMessage: message.toDictionary()
        ]

        if let actionName = actionName {
            data[CustomerioConstants.actionName] = actionName
        }
        if let actionValue = actionValue {
            data[CustomerioConstants.actionValue] = actionValue
        }

        eventEmitter?(data)
    }

    public func messageActionTaken(message: InboxMessage, actionName: String, actionValue: String) -> Bool {
        emitInboxEvent(
            eventType: CustomerioConstants.messageActionTaken,
            message: message,
            actionName: actionName,
            actionValue: actionValue
        )
        // Host (React Native) owns action handling while a listener is registered.
        return true
    }

    public func messageShown(message: InboxMessage) {
        emitInboxEvent(eventType: CustomerioConstants.messageShown, message: message)
    }

    public func messageOpened(message: InboxMessage) {
        emitInboxEvent(eventType: CustomerioConstants.messageOpened, message: message)
    }

    public func messageDismissed(message: InboxMessage) {
        emitInboxEvent(eventType: CustomerioConstants.messageDismissed, message: message)
    }
}
