import CioMessagingInApp
import Foundation

/// React Native wrapper for NotificationInboxChangeListener.
/// Singleton instance that forwards inbox message changes to React Native event emitter.
/// All methods run on MainActor as required by the protocol.
@MainActor
class ReactNotificationInboxChangeListener: NotificationInboxChangeListener {
    // Event emitter function to send events to React Native layer
    private var eventEmitter: (([String: Any]) -> Void)?

    // Sets the event emitter function
    func setEventEmitter(emitter: (([String: Any]) -> Void)?) {
        eventEmitter = emitter
    }

    // Clears the event emitter to prevent memory leaks
    func clearEventEmitter() {
        eventEmitter = nil
    }

    // Called when inbox messages change
    func onMessagesChanged(messages: [InboxMessage]) {
        guard let emitter = eventEmitter else {
            return
        }

        let messagesArray = messages.map { $0.toDictionary() }
        let payload: [String: Any] = ["messages": messagesArray]

        emitter(payload)
    }

    // Singleton instance
    static let shared = ReactNotificationInboxChangeListener()
    private init() {}
}
