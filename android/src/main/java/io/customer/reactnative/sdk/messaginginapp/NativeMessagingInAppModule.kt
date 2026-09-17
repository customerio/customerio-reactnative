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
import io.customer.messaginginapp.type.ColorScheme
import io.customer.messaginginapp.type.NotificationInboxAccessibilityLabels
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
    private val inboxEventListener = ReactInboxEventListener.instance

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
        clearInboxEventListener()
        super.invalidate()
    }

    override fun dismissMessage() {
        inAppMessagingModule?.dismissMessage()
    }

    override fun setColorScheme(colorScheme: String) {
        val resolved = colorSchemeFromRawValue(colorScheme, logger)
        if (resolved == null) {
            // Unrecognized value: leave the current scheme alone rather than resetting it to
            // AUTO, so a typo cannot quietly undo a scheme the app set correctly earlier.
            return
        }
        val module = inAppMessagingModule
        if (module == null) {
            // Reachable when the host calls this before CustomerIO.initialize, or without the
            // in-app module configured. Logged rather than ignored: the scheme is silently not
            // applied, and nothing else surfaces that.
            logger.error(
                "In-app messaging is not available, so the color scheme was not applied. " +
                    "Ensure CustomerIO SDK is initialized with the inApp configuration."
            )
            return
        }
        module.setColorScheme(resolved)
    }

    override fun setupInboxListener() {
        setupInboxChangeListener()
    }

    /**
     * Registers the native inbox event forwarder with the SDK and wires it to the React Native
     * event emitter. Called when a JS inbox event listener is registered.
     */
    override fun registerInboxEventListener() {
        inboxEventListener.setEventEmitter { data ->
            emitOnInboxEventReceived(data)
        }
        val module = inAppMessagingModule
        if (module == null) {
            // Without this the failure is invisible: the JS subscription reports success while the SDK
            // never forwards anything, so inbox callbacks silently never arrive. Matches the guidance
            // used by getMessages() for the same situation.
            logger.error(
                "Cannot register inbox event listener: in-app messaging is not available. " +
                    "Ensure CustomerIO SDK is initialized before registering the listener."
            )
            return
        }
        module.setInboxEventListener(inboxEventListener)
    }

    /**
     * Unregisters the native inbox event forwarder by installing a no-op listener (the native API is
     * non-null), restoring the SDK's default action handling. Called when the JS inbox event
     * listener is removed.
     */
    override fun unregisterInboxEventListener() {
        inAppMessagingModule?.setInboxEventListener(NoOpInboxEventListener)
        inboxEventListener.clearEventEmitter()
    }

    private fun clearInboxEventListener() {
        inAppMessagingModule?.setInboxEventListener(NoOpInboxEventListener)
        inboxEventListener.clearEventEmitter()
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
                    colorSchemeFromConfig(config)?.let { colorScheme ->
                        setColorScheme(colorScheme)
                    }
                    inboxAccessibilityLabelsFromConfig(config)?.let { labels ->
                        setNotificationInboxAccessibilityLabels(labels)
                    }
                }.build(),
            )
            builder.addCustomerIOModule(module)
        }

        /**
         * Maps the wrapper's `colorScheme` value onto the native [ColorScheme], or null when the
         * host provided none — in which case the caller leaves the SDK's own AUTO default alone.
         *
         * The accepted values are lowercase because that is the wire contract the JavaScript
         * `CioColorScheme` enum serializes to and the one iOS already matches. An unrecognized
         * value returns null and logs, rather than falling back to AUTO silently: the failure mode
         * is a message rendered in the wrong theme, which looks like a styling bug rather than a
         * configuration mistake.
         */
        internal fun colorSchemeFromRawValue(rawValue: String?, logger: Logger): ColorScheme? {
            if (rawValue == null) return null

            return when (rawValue) {
                "auto" -> ColorScheme.AUTO
                "light" -> ColorScheme.LIGHT
                "dark" -> ColorScheme.DARK
                else -> {
                    logger.error(
                        "Unrecognized in-app colorScheme '$rawValue', expected one of " +
                            "auto, light, dark. Leaving the color scheme unchanged."
                    )
                    null
                }
            }
        }

        private fun colorSchemeFromConfig(config: Map<String, Any>): ColorScheme? =
            colorSchemeFromRawValue(
                config.getTypedValue<String>(Keys.Config.COLOR_SCHEME),
                SDKComponent.logger
            )

        /**
         * Builds the host's inbox accessibility labels from the wrapper configuration, or null when
         * the app provided none — in which case the SDK keeps its default of emitting no labels at
         * all rather than falling back to English.
         *
         * `bellWithUnreadCount` arrives as a template string because the bridge carries data but not
         * functions; it is converted here into the `(Int) -> String` the native SDK expects. A
         * template without the placeholder is returned verbatim for every count; the JavaScript
         * layer warns about that case, where the developer can actually see it.
         */
        private fun inboxAccessibilityLabelsFromConfig(
            config: Map<String, Any>
        ): NotificationInboxAccessibilityLabels? {
            val labels = config.getTypedValue<Map<String, Any>>(
                Keys.Config.NOTIFICATION_INBOX_ACCESSIBILITY_LABELS
            ) ?: return null

            val unreadCountTemplate = labels.getTypedValue<String>(
                Keys.InboxAccessibilityLabels.BELL_WITH_UNREAD_COUNT
            )
            return NotificationInboxAccessibilityLabels(
                bell = labels.getTypedValue<String>(Keys.InboxAccessibilityLabels.BELL),
                bellWithUnreadCount = unreadCountTemplate?.let { template ->
                    { count: Int ->
                        template.replace(
                            Keys.InboxAccessibilityLabels.COUNT_PLACEHOLDER,
                            count.toString()
                        )
                    }
                },
                loadingIndicator = labels.getTypedValue<String>(
                    Keys.InboxAccessibilityLabels.LOADING_INDICATOR
                ),
                emptyState = labels.getTypedValue<String>(
                    Keys.InboxAccessibilityLabels.EMPTY_STATE
                )
            )
        }
    }
}
