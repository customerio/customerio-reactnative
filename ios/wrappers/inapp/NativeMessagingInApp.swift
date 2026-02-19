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

    // Flag to track inbox listener setup state
    // Note: Theoretical race condition exists (check before Task completes), but acceptable because:
    // 1. React Native TurboModule calls are serialized on JS thread
    // 2. Duplicate registrations use same singleton listener instance (harmless)
    // 3. Native SDK handles duplicate listener registrations gracefully
    private var isInboxChangeListenerSetup = false

    // Computed property to access inbox instance
    private var inbox: NotificationInbox {
        MessagingInApp.shared.inbox
    }

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

    /**
     * Dismisses any currently displayed in-app message
     */
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
        Task {
            // Use native topic filtering - SDK handles filtering and case sensitivity
            let messages = await inbox.getMessages(topic: topic)
            let messagesArray = messages.map { $0.toDictionary() }
            resolve(messagesArray)
        }
    }

    @objc(markMessageOpened:)
    public func markMessageOpened(message: NSDictionary) {
        guard let inboxMessage = parseInboxMessage(from: message) else { return }
        inbox.markMessageOpened(message: inboxMessage)
    }

    @objc(markMessageUnopened:)
    public func markMessageUnopened(message: NSDictionary) {
        guard let inboxMessage = parseInboxMessage(from: message) else { return }
        inbox.markMessageUnopened(message: inboxMessage)
    }

    @objc(markMessageDeleted:)
    public func markMessageDeleted(message: NSDictionary) {
        guard let inboxMessage = parseInboxMessage(from: message) else { return }
        inbox.markMessageDeleted(message: inboxMessage)
    }

    @objc(trackMessageClicked:actionName:)
    public func trackMessageClicked(message: NSDictionary, actionName: String?) {
        guard let inboxMessage = parseInboxMessage(from: message) else { return }
        inbox.trackMessageClicked(message: inboxMessage, actionName: actionName)
    }

    // MARK: - Helper Methods

    // Clears the in-app event listener to prevent leaks when module is deallocated or invalidated
    func clearInAppEventListener() {
        ReactInAppEventListener.shared.clearEventEmitter()
    }

    /**
     * Sets up the inbox change listener to receive real-time updates.
     * This method can be called multiple times safely and will only set up the listener once.
     * Note: Inbox must be available (SDK initialized) before this can succeed.
     */
    private func setupInboxChangeListener() {
        // Only set up once to avoid duplicate listeners
        guard !isInboxChangeListenerSetup else {
            return
        }

        // All listener setup must run on MainActor
        Task { @MainActor in
            let listener = ReactNotificationInboxChangeListener.shared

            listener.setEventEmitter { [weak self] data in
                guard let self else { return }
                self.sendInboxChangeEvent(data: data)
            }

            // Add listener to inbox without topic filter (all messages)
            // Topic filtering happens client-side in TypeScript layer
            inbox.addChangeListener(listener)

            // Set flag after successful setup (allows retry if setup was called before SDK initialized)
            self.isInboxChangeListenerSetup = true
        }
    }

    private func clearInboxChangeListener() {
        guard isInboxChangeListenerSetup else {
            return
        }

        // All listener cleanup must run on MainActor
        Task { @MainActor in
            let listener = ReactNotificationInboxChangeListener.shared
            inbox.removeChangeListener(listener)
            listener.clearEventEmitter()

            // Reset flag after cleanup completes
            self.isInboxChangeListenerSetup = false
        }
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

// MARK: - NativeMessagingInApp Extension

extension NativeMessagingInApp {
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
}
