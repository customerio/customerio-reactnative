package io.customer.reactnative.sdk.messaginginapp

import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactContextBaseJavaModule
import com.facebook.react.bridge.ReactMethod
import com.facebook.react.modules.core.DeviceEventManagerModule
import io.customer.messaginginapp.MessagingInAppModuleConfig
import io.customer.messaginginapp.ModuleMessagingInApp
import io.customer.messaginginapp.di.inAppMessaging
import io.customer.messaginginapp.type.InAppEventListener
import io.customer.messaginginapp.type.InAppMessage
import io.customer.reactnative.sdk.constant.Keys
import io.customer.reactnative.sdk.extension.getTypedValue
import io.customer.sdk.CustomerIO
import io.customer.sdk.CustomerIOBuilder
import io.customer.sdk.core.di.SDKComponent
import io.customer.sdk.data.model.Region

/**
 * ReactNative module to hold in-app messages features in a single place to bridge with native code.
 */
class RNCIOInAppMessaging(
    private val reactContext: ReactApplicationContext,
) : ReactContextBaseJavaModule(reactContext), InAppEventListener {
    override fun getName(): String = "CioRctInAppMessaging"

    private val inAppMessagingModule: ModuleMessagingInApp?
        get() = kotlin.runCatching { CustomerIO.instance().inAppMessaging() }.getOrNull()

    private var listenerCount = 0

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
                setEventListener(eventListener = this@RNCIOInAppMessaging)
            }.build(),
        )
        builder.addCustomerIOModule(module)
    }

    @ReactMethod
    fun addListener(eventName: String) {
        listenerCount++
    }

    @ReactMethod
    fun removeListeners(count: Int) {
        listenerCount -= count
    }

    /**
     * Dismisses any currently displayed in-app message
     */
    @ReactMethod
    fun dismissMessage() {
        inAppMessagingModule?.dismissMessage()
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
            .emit("InAppEventListener", Arguments.makeNativeMap(data))
    }

    override fun errorWithMessage(message: InAppMessage) = sendEvent(
        eventType = "errorWithMessage",
        message = message,
    )

    override fun messageActionTaken(
        message: InAppMessage,
        actionValue: String,
        actionName: String,
    ) = sendEvent(eventType = "messageActionTaken", message = message, extras = buildMap {
        put("actionValue", actionValue)
        put("actionName", actionName)
    })

    override fun messageDismissed(message: InAppMessage) = sendEvent(
        eventType = "messageDismissed",
        message = message,
    )

    override fun messageShown(message: InAppMessage) = sendEvent(
        eventType = "messageShown",
        message = message,
    )
}
