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
class RNCIOInAppEventListener(
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

    private fun sendEvent(eventType: String, params: Map<String, *>?) {
        if (listenerCount <= 0) return

        val args = (params ?: emptyMap<String, Any?>())
            .plus(map = mapOf("eventType" to eventType))
            .let { Arguments.makeNativeMap(it) }
        reactContext
            .getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter::class.java)
            .emit("InAppEventListener", args)
    }

    override fun errorWithMessage(message: InAppMessage) = sendEvent(
        eventType = "errorWithMessage",
        params = message.toMap(),
    )

    override fun messageActionTaken(
        message: InAppMessage,
        action: String,
        name: String,
    ) = sendEvent(
        eventType = "messageActionTaken",
        params = message.toMap().plus(
            mapOf(
                "action" to action,
                "name" to name,
            ),
        ),
    )

    override fun messageDismissed(message: InAppMessage) = sendEvent(
        eventType = "messageDismissed",
        params = message.toMap(),
    )

    override fun messageShown(message: InAppMessage) = sendEvent(
        eventType = "messageShown",
        params = message.toMap(),
    )

    override fun getName(): String = "CustomerIOInAppEventListener"
}

private fun InAppMessage.toMap() = mapOf(
    "messageId" to messageId,
    "deliveryId" to deliveryId,
)
