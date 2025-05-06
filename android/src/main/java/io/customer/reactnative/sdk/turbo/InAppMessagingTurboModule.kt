package io.customer.reactnative.sdk.turbo

import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.modules.core.DeviceEventManagerModule
import com.facebook.react.turbomodule.core.interfaces.TurboModule
import io.customer.messaginginapp.MessagingInAppModuleConfig
import io.customer.messaginginapp.ModuleMessagingInApp
import io.customer.messaginginapp.di.inAppMessaging
import io.customer.messaginginapp.type.InAppEventListener
import io.customer.messaginginapp.type.InAppMessage
import io.customer.sdk.CustomerIO
import io.customer.sdk.CustomerIOBuilder
import io.customer.sdk.core.di.SDKComponent
import io.customer.sdk.data.model.Region

/**
 * TurboModule implementation for CustomerIO In-App Messaging functionality
 */
class InAppMessagingTurboModule(
    private val reactContext: ReactApplicationContext
) : TurboModule, InAppEventListener {

    override fun getName(): String = "InAppMessagingModule"

    private val inAppMessagingModule: ModuleMessagingInApp?
        get() = kotlin.runCatching { CustomerIO.instance().inAppMessaging() }.getOrNull()

    private var listenerCount = 0

    // Constants for event names
    private val inAppEventListenerEventName = "InAppEventListener"
    private val messageShownEvent = "messageShown"
    private val messageDismissedEvent = "messageDismissed"
    private val messageActionTakenEvent = "messageActionTaken"
    private val errorWithMessageEvent = "errorWithMessage"

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
        val siteId = config["siteId"] as? String
        if (siteId.isNullOrBlank()) {
            SDKComponent.logger.error("Site ID is required to initialize InAppMessaging module")
            return
        }

        val module = ModuleMessagingInApp(
            MessagingInAppModuleConfig.Builder(siteId = siteId, region = region).apply {
                setEventListener(eventListener = this@InAppMessagingTurboModule)
            }.build(),
        )
        builder.addCustomerIOModule(module)
    }

    /**
     * Add a listener for in-app messaging events
     */
    fun addListener(eventName: String) {
        listenerCount++
    }

    /**
     * Remove listeners for in-app messaging events
     */
    fun removeListeners(count: Int) {
        listenerCount -= count
    }

    /**
     * Dismisses any currently displayed in-app message
     */
    fun dismissMessage() {
        inAppMessagingModule?.dismissMessage()
    }

    /**
     * Get the name of the event listener
     */
    fun getInAppEventListenerEventName(): String {
        return inAppEventListenerEventName
    }

    /**
     * Get the event constants
     */
    fun getEvents(): Map<String, String> {
        return mapOf(
            "MessageShown" to messageShownEvent,
            "MessageDismissed" to messageDismissedEvent,
            "MessageActionTaken" to messageActionTakenEvent,
            "ErrorWithMessage" to errorWithMessageEvent
        )
    }

    /**
     * Sends event to JS Callback. All events are sent under one name so it easier for customers to
     * listen on multiple linked events. The [eventType], [message] values and [extras] are merged
     * and passed in single map as arguments.
     */
    private fun sendEvent(
        eventType: String,
        message: InAppMessage,
        extras: Map<String, Any> = emptyMap(),
    ) {
        if (listenerCount <= 0) return

        val data = buildMap {
            put("eventType", eventType)
            put("messageId", message.messageId)
            put("deliveryId", message.deliveryId)
            putAll(extras)
        }

        reactContext
            .getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter::class.java)
            .emit(inAppEventListenerEventName, Arguments.makeNativeMap(data))
    }

    override fun errorWithMessage(message: InAppMessage) = sendEvent(
        eventType = errorWithMessageEvent,
        message = message,
    )

    override fun messageActionTaken(
        message: InAppMessage,
        actionValue: String,
        actionName: String,
    ) = sendEvent(eventType = messageActionTakenEvent, message = message, extras = buildMap {
        put("actionValue", actionValue)
        put("actionName", actionName)
    })

    override fun messageDismissed(message: InAppMessage) = sendEvent(
        eventType = messageDismissedEvent,
        message = message,
    )

    override fun messageShown(message: InAppMessage) = sendEvent(
        eventType = messageShownEvent,
        message = message,
    )
}