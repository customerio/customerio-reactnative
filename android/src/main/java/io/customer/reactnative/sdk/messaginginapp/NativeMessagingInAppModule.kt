package io.customer.reactnative.sdk.messaginginapp

import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.Promise
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReadableMap
import io.customer.messaginginapp.MessagingInAppModuleConfig
import io.customer.messaginginapp.ModuleMessagingInApp
import io.customer.messaginginapp.di.inAppMessaging
import io.customer.messaginginapp.gist.data.model.InboxMessage
import io.customer.messaginginapp.gist.data.model.response.InboxMessageFactory
import io.customer.messaginginapp.inbox.NotificationInbox
import io.customer.reactnative.sdk.NativeCustomerIOMessagingInAppSpec
import io.customer.reactnative.sdk.constant.Keys
import io.customer.reactnative.sdk.extension.getTypedValue
import io.customer.reactnative.sdk.extension.toMap
import io.customer.sdk.CustomerIO
import io.customer.sdk.CustomerIOBuilder
import io.customer.sdk.core.di.SDKComponent
import io.customer.sdk.core.util.Logger
import io.customer.sdk.data.model.Region

/**
 * React Native module implementation for Customer.io In-App Messaging Native SDK
 * using TurboModules with new architecture.
 */
class NativeMessagingInAppModule(
    reactContext: ReactApplicationContext,
) : NativeCustomerIOMessagingInAppSpec(reactContext) {
    private val logger: Logger = SDKComponent.logger
    private val inAppMessagingModule: ModuleMessagingInApp?
        get() = runCatching { CustomerIO.instance().inAppMessaging() }.getOrNull()

    private val inAppEventListener = ReactInAppEventListener.instance
    private val inboxChangeListener = ReactNotificationInboxChangeListener.instance

    // Dedicated lock for inbox listener setup to avoid blocking other operations
    private val inboxListenerLock = Any()
    private var isInboxChangeListenerSetup = false

    /**
     * Returns NotificationInbox instance if available, null otherwise, logging error on failure.
     * Note: Notification Inbox is only available after SDK is initialized.
     */
    private fun requireInboxInstance(): NotificationInbox? {
        val inbox = inAppMessagingModule?.inbox()
        if (inbox == null) {
            logger.error("Notification Inbox is not available. Ensure CustomerIO SDK is initialized.")
        }
        return inbox
    }

    override fun initialize() {
        super.initialize()
        inAppEventListener.setEventEmitter { data ->
            emitOnInAppEventReceived(data)
        }
        // Note: Inbox change listener is set up lazily when inbox is first accessed via
        // setupInboxListener() and not here as Notification Inbox becomes available only after
        // CustomerIO.initialize() is called, which may not have happened yet at this point.
    }

    override fun invalidate() {
        inAppEventListener.clearEventEmitter()
        clearInboxChangeListener()
        super.invalidate()
    }

    override fun dismissMessage() {
        inAppMessagingModule?.dismissMessage()
    }

    override fun setupInboxListener() {
        setupInboxChangeListener()
    }

    override fun getMessages(topic: String?, promise: Promise?) {
        try {
            val inbox = requireInboxInstance() ?: run {
                promise?.reject(
                    "INBOX_NOT_AVAILABLE",
                    "Notification Inbox is not available. Ensure CustomerIO SDK is initialized."
                )
                return
            }

            inbox.fetchMessages(topic) { result ->
                result.onSuccess { messages ->
                    val messagesArray = Arguments.createArray()
                    messages.forEach { message ->
                        messagesArray.pushMap(message.toWritableMap())
                    }
                    promise?.resolve(messagesArray)
                }.onFailure { error ->
                    promise?.reject(
                        "FETCH_FAILED",
                        error.localizedMessage ?: "Failed to fetch messages"
                    )
                }
            }
        } catch (e: Exception) {
            promise?.reject("FETCH_ERROR", e.localizedMessage ?: "Unknown error")
        }
    }

    override fun markMessageOpened(message: ReadableMap?) {
        performInboxMessageAction(message) { inbox, inboxMessage ->
            inbox.markMessageOpened(inboxMessage)
        }
    }

    override fun markMessageUnopened(message: ReadableMap?) {
        performInboxMessageAction(message) { inbox, inboxMessage ->
            inbox.markMessageUnopened(inboxMessage)
        }
    }

    override fun markMessageDeleted(message: ReadableMap?) {
        performInboxMessageAction(message) { inbox, inboxMessage ->
            inbox.markMessageDeleted(inboxMessage)
        }
    }

    override fun trackMessageClicked(message: ReadableMap?, actionName: String?) {
        performInboxMessageAction(message) { inbox, inboxMessage ->
            inbox.trackMessageClicked(inboxMessage, actionName)
        }
    }

    /**
     * Sets up the inbox change listener to receive real-time updates.
     * This method can be called multiple times safely and will only set up the listener once.
     * Note: Inbox must be available (SDK initialized) before this can succeed.
     */
    private fun setupInboxChangeListener() {
        synchronized(inboxListenerLock) {
            // Only set up once to avoid duplicate listeners
            if (isInboxChangeListenerSetup) {
                return
            }

            val inbox = requireInboxInstance() ?: run {
                logger.debug("Inbox not available yet, skipping listener setup")
                return
            }

            inboxChangeListener.setEventEmitter(
                emitter = { data ->
                    emitSubscribeToMessagesChanged(data)
                }
            )
            inbox.addChangeListener(inboxChangeListener)
            isInboxChangeListenerSetup = true
            logger.debug("NotificationInboxChangeListener set up successfully")
        }
    }

    private fun clearInboxChangeListener() {
        synchronized(inboxListenerLock) {
            if (!isInboxChangeListenerSetup) {
                return
            }
            requireInboxInstance()?.removeChangeListener(inboxChangeListener)
            inboxChangeListener.clearEventEmitter()
            isInboxChangeListenerSetup = false
        }
    }

    /**
     * Helper to validate inbox instance and message data before performing a message action.
     * Returns early if inbox is unavailable or message data is invalid.
     */
    private fun performInboxMessageAction(
        message: ReadableMap?,
        action: (NotificationInbox, InboxMessage) -> Unit
    ) {
        val inbox = requireInboxInstance() ?: return
        val inboxMessage = InboxMessageFactory.fromMap(message.toMap()) ?: run {
            logger.error("Invalid message data: $message")
            return
        }
        action(inbox, inboxMessage)
    }

    companion object {
        internal const val NAME = "NativeCustomerIOMessagingInApp"

        /**
         * Adds InAppMessaging module to native Android SDK based on configuration provided by customer
         * app.
         *
         * @param builder CustomerIOBuilder instance to add InAppMessaging module
         * @param config Configuration provided by customer app for InAppMessaging module
         * @param region Region to be used for InAppMessaging module
         */
        internal fun addNativeModuleFromConfig(
            builder: CustomerIOBuilder,
            config: Map<String, Any>,
            region: Region
        ) {
            val siteId = config.getTypedValue<String>(Keys.Config.SITE_ID)
            if (siteId.isNullOrBlank()) {
                SDKComponent.logger.error("Site ID is required to initialize InAppMessaging module")
                return
            }

            val module = ModuleMessagingInApp(
                MessagingInAppModuleConfig.Builder(siteId = siteId, region = region).apply {
                    setEventListener(eventListener = ReactInAppEventListener.instance)
                }.build(),
            )
            builder.addCustomerIOModule(module)
        }
    }
}
