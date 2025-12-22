package io.customer.reactnative.sdk.messaginginapp

import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.ReadableMap
import io.customer.messaginginapp.type.InAppEventListener
import io.customer.messaginginapp.type.InAppMessage

/**
 * React Native bridge for Customer.io in-app messaging events.
 * Converts native SDK events to JavaScript compatible format.
 */
class ReactInAppEventListener private constructor() : InAppEventListener {
    // Event emitter function to send events to React Native layer
    private var eventEmitter: ((ReadableMap) -> Unit)? = null

    // Sets the event emitter function
    internal fun setEventEmitter(emitter: ((ReadableMap) -> Unit)?) {
        this.eventEmitter = emitter
    }

    // Clears the event emitter to prevent memory leaks
    internal fun clearEventEmitter() {
        this.eventEmitter = null
    }

    // Emits an in-app message event to React Native with unified event structure
    private fun emitInAppEvent(
        eventType: String,
        message: InAppMessage,
        actionValue: String? = null,
        actionName: String? = null,
    ) {
        // Get the emitter, return early if not set
        val emitter = eventEmitter ?: return

        val data = buildMap {
            put("eventType", eventType)
            put("messageId", message.messageId)
            put("deliveryId", message.deliveryId)
            actionValue?.let { put("actionValue", it) }
            actionName?.let { put("actionName", it) }
        }

        emitter.invoke(Arguments.makeNativeMap(data))
    }

    override fun errorWithMessage(message: InAppMessage) = emitInAppEvent(
        eventType = "errorWithMessage",
        message = message,
    )

    override fun messageActionTaken(
        message: InAppMessage,
        actionValue: String,
        actionName: String,
    ) = emitInAppEvent(
        eventType = "messageActionTaken",
        message = message,
        actionValue = actionValue,
        actionName = actionName,
    )

    override fun messageDismissed(message: InAppMessage) = emitInAppEvent(
        eventType = "messageDismissed",
        message = message,
    )

    override fun messageShown(message: InAppMessage) = emitInAppEvent(
        eventType = "messageShown",
        message = message,
    )

    companion object {
        // Singleton instance with public visibility for direct access by Expo plugin
        val instance: ReactInAppEventListener by lazy { ReactInAppEventListener() }
    }
}
