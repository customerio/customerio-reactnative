package io.customer.reactnative.sdk

import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactContextBaseJavaModule
import com.facebook.react.bridge.ReactMethod
import com.facebook.react.modules.core.DeviceEventManagerModule
import io.customer.messaginginapp.type.InAppEventListener
import io.customer.messaginginapp.type.InAppMessage

/**
 * ReactNative module to hold in-app messages features in a single place to bridge with native code.
 */
class RNCIOInAppMessaging(
    private val reactContext: ReactApplicationContext,
) : ReactContextBaseJavaModule(reactContext), InAppEventListener {
    private var listenerCount = 0

    @ReactMethod
    fun addListener(eventName: String) {
        listenerCount++
    }

    @ReactMethod
    fun removeListeners(count: Int) {
        listenerCount -= count
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
        "actionValue" to actionValue
        "actionName" to actionName
    })

    override fun messageDismissed(message: InAppMessage) = sendEvent(
        eventType = "messageDismissed",
        message = message,
    )

    override fun messageShown(message: InAppMessage) = sendEvent(
        eventType = "messageShown",
        message = message,
    )

    override fun getName(): String = "CustomerioInAppMessaging"
}
