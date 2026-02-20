import CioInternalCommon
import CioMessagingInApp
import Foundation
import React

// In-app messaging module for new React Native architecture (TurboModule)
@objc(NativeMessagingInApp)
public class NativeMessagingInApp: NSObject {
    // Reference to the ObjC event emitter for new architecture (TurboModule)
    private weak var objcEventEmitter: AnyObject?
    private lazy var inAppEventCallback: (_ body: [String: Any]) -> Void = { [weak self] body in
        self?.sendEvent(body: body)
    }

    private let logger: CioInternalCommon.Logger = DIGraphShared.shared.logger

    // Task that consumes the inbox messages stream
    private var messagesStreamTask: Task<Void, Never>?

    // Set ObjC event emitter reference for new architecture
    @objc
    public func setEventEmitter(_ emitter: AnyObject) {
        objcEventEmitter = emitter
    }

    // Initialize in-app event listener - called by React Native
    @objc
    public func initialize() {
        // Initialize in-app event listener - called by React Native
        ReactInAppEventListener.shared.setEventEmitter { [weak self] data in
            guard let self else { return }

            // Filter out nil values to convert [String: Any?] to [String: Any]
            let body = data.compactMapValues { $0 }
            inAppEventCallback(body)
        }
        // If MessagingInApp module has already been initialized, this sets the listener directly.
        // If this method is called early, accessing ReactInAppEventListener.shared will also register
        // it into the DI graph, making it available for access in Expo during auto-initialization.
        MessagingInApp.shared.setEventListener(ReactInAppEventListener.shared)

        // Note: Inbox change listener is set up lazily when inbox is first accessed via
        // setupInboxListener(), not here. Notification Inbox becomes available only after
        // CustomerIO.initialize() is called, which may not have happened yet at this point.
    }

    // Clear in-app event listener to prevent memory leaks - called by React Native
    @objc
    public func invalidate() {
        // Clear in-app event listener to prevent leaks
        clearInAppEventListener()
        clearInboxChangeListener()
    }

    /// Dismisses any currently displayed in-app message
    @objc(dismissMessage)
    public func dismissMessage() {
        MessagingInApp.shared.dismissMessage()
    }

    // MARK: - Inbox Methods

    @objc(setupInboxListener)
    public func setupInboxListener() {
        setupInboxChangeListener()
    }

    @objc(getMessages:resolve:reject:)
    public func getMessages(topic: String?, resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
        guard let inbox = requireInboxInstance() else {
            reject(
                "INBOX_NOT_AVAILABLE",
                "Notification Inbox is not available. Ensure CustomerIO SDK is initialized.",
                nil
            )
            return
        }

        Task {
            // Use native topic filtering - SDK handles filtering and case sensitivity
            let messages = await inbox.getMessages(topic: topic)
            let messagesArray = messages.map { $0.toDictionary() }
            resolve(messagesArray)
        }
    }

    @objc(markMessageOpened:)
    public func markMessageOpened(message: NSDictionary) {
        performInboxMessageAction(message: message) { inbox, inboxMessage in
            inbox.markMessageOpened(message: inboxMessage)
        }
    }

    @objc(markMessageUnopened:)
    public func markMessageUnopened(message: NSDictionary) {
        performInboxMessageAction(message: message) { inbox, inboxMessage in
            inbox.markMessageUnopened(message: inboxMessage)
        }
    }

    @objc(markMessageDeleted:)
    public func markMessageDeleted(message: NSDictionary) {
        performInboxMessageAction(message: message) { inbox, inboxMessage in
            inbox.markMessageDeleted(message: inboxMessage)
        }
    }

    @objc(trackMessageClicked:actionName:)
    public func trackMessageClicked(message: NSDictionary, actionName: String?) {
        performInboxMessageAction(message: message) { inbox, inboxMessage in
            inbox.trackMessageClicked(message: inboxMessage, actionName: actionName)
        }
    }

    // MARK: - Helper Methods

    // Clears the in-app event listener to prevent leaks when module is deallocated or invalidated
    func clearInAppEventListener() {
        ReactInAppEventListener.shared.clearEventEmitter()
    }

    /// Returns inbox instance if available, nil otherwise with error logging
    /// Note: Notification Inbox is only available after SDK is initialized
    private func requireInboxInstance() -> NotificationInbox? {
        guard MessagingInApp.shared.implementation != nil else {
            logger.error("Notification Inbox is not available. Ensure CustomerIO SDK is initialized.")
            return nil
        }
        return MessagingInApp.shared.inbox
    }

    /// Parses NSDictionary to InboxMessage with error logging
    private func parseInboxMessage(from dictionary: NSDictionary) -> InboxMessage? {
        guard let dict = dictionary as? [String: Any],
              let inboxMessage = InboxMessageFactory.fromDictionary(dict)
        else {
            logger.error("Invalid message data: \(dictionary)")
            return nil
        }
        return inboxMessage
    }

    /// Helper to validate inbox availability and message data before performing a message action
    /// Returns early if inbox is unavailable or message data is invalid
    private func performInboxMessageAction(
        message: NSDictionary,
        action: (NotificationInbox, InboxMessage) -> Void
    ) {
        guard let inbox = requireInboxInstance() else { return }
        guard let inboxMessage = parseInboxMessage(from: message) else { return }
        action(inbox, inboxMessage)
    }

    /// Sets up the inbox change listener to receive real-time updates.
    /// This method can be called multiple times safely and will only set up the listener once.
    /// Note: Inbox must be available (SDK initialized) before this can succeed.
    private func setupInboxChangeListener() {
        // Only set up once to avoid duplicate listeners
        guard messagesStreamTask == nil else {
            return
        }

        // Check if SDK is initialized before attempting setup
        guard let inbox = requireInboxInstance() else {
            return
        }

        // Consume messages stream asynchronously
        messagesStreamTask = Task { [weak self] in
            for await messages in inbox.messages(topic: nil) {
                guard let self else { return }

                // Emit messages to React Native
                let messagesArray = messages.map { $0.toDictionary() }
                let payload: [String: Any] = ["messages": messagesArray]
                self.sendInboxChangeEvent(data: payload)
            }
        }
    }

    private func clearInboxChangeListener() {
        // Cancel the stream consumption task - this automatically cleans up the stream
        messagesStreamTask?.cancel()
        messagesStreamTask = nil
    }

    private func sendInboxChangeEvent(data: [String: Any]) {
        guard let emitter = objcEventEmitter else {
            return
        }

        let selector = Selector(("emitSubscribeToMessagesChanged:"))
        guard emitter.responds(to: selector) else {
            return
        }
        _ = emitter.perform(selector, with: data as NSDictionary)
    }

    // Send in-app event to React Native layer using ObjC event emitter
    private func sendEvent(body: [String: Any]) {
        guard let emitter = objcEventEmitter else {
            assertionFailure("NativeMessagingInApp: ObjC event emitter is nil, cannot send in-app event")
            return
        }

        // New architecture: use injected ObjC event emitter from TurboModule
        let selector = Selector(("emitOnInAppEventReceived:"))
        guard emitter.responds(to: selector) else {
            assertionFailure("ObjC event emitter does not respond to selector: emitOnInAppEventReceived:")
            return
        }
        _ = emitter.perform(selector, with: body as NSDictionary)
    }
}
