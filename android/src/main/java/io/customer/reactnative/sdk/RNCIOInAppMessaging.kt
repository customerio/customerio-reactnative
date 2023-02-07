package io.customer.reactnative.sdk

import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactContextBaseJavaModule
import com.facebook.react.bridge.ReactMethod
import com.facebook.react.modules.core.DeviceEventManagerModule
import io.customer.messaginginapp.type.InAppEventListener
import io.customer.messaginginapp.type.InAppMessage

/**
 * Wrapper class that bridges JS Callbacks to native callbacks for in-app messaging.
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

    private fun sendEvent(
        eventType: String,
        message: InAppMessage,
        extras: Map<String, Any> = emptyMap(),
    ) {
        if (listenerCount <= 0) return

        val data = buildMap {
            putAll(extras)
            put("deliveryId", message.deliveryId)
            put("messageId", message.messageId)
        }
        val args = Arguments.createMap().apply {
            putString("eventType", eventType)
            putMap("data", Arguments.makeNativeMap(data))
        }

        reactContext
            .getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter::class.java)
            .emit("InAppEventListener", args)
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
