package io.customer.reactnative.sdk.messaginginapp

import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.ReadableMap
import io.customer.messaginginapp.gist.data.model.InboxMessage
import io.customer.messaginginapp.type.InboxEventListener

/**
 * React Native bridge for Customer.io Visual Notification Inbox events.
 *
 * Registered on the SDK (via [io.customer.messaginginapp.ModuleMessagingInApp.setInboxEventListener])
 * only while a JS listener is registered. Because the New-Arch event emitter is one-way we cannot
 * round-trip a bool back from JS, so [messageActionTaken] forwards the event fire-and-forget and
 * RETURNS `true` — telling the SDK the host handled the action so the SDK suppresses its default
 * navigation. The JS host owns action handling while a listener is registered. Observational
 * callbacks forward fire-and-forget.
 */
class ReactInboxEventListener private constructor() : InboxEventListener {
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

    // Emits an inbox message event to React Native with a serialized message payload
    private fun emitInboxEvent(
        eventType: String,
        message: InboxMessage,
        actionName: String? = null,
        actionValue: String? = null,
    ) {
        // Get the emitter, return early if not set
        val emitter = eventEmitter ?: return

        val data = Arguments.createMap().apply {
            putString("eventType", eventType)
            putMap("message", message.toWritableMap())
            actionName?.let { putString("actionName", it) }
            actionValue?.let { putString("actionValue", it) }
        }

        emitter.invoke(data)
    }

    override fun messageActionTaken(
        message: InboxMessage,
        actionName: String,
        actionValue: String,
    ): Boolean {
        emitInboxEvent(
            eventType = "messageActionTaken",
            message = message,
            actionName = actionName,
            actionValue = actionValue,
        )
        // Host (React Native) owns action handling while a listener is registered.
        return true
    }

    override fun messageShown(message: InboxMessage) = emitInboxEvent(
        eventType = "messageShown",
        message = message,
    )

    override fun messageOpened(message: InboxMessage) = emitInboxEvent(
        eventType = "messageOpened",
        message = message,
    )

    override fun messageDismissed(message: InboxMessage) = emitInboxEvent(
        eventType = "messageDismissed",
        message = message,
    )

    companion object {
        // Singleton instance with public visibility for direct access by Expo plugin
        val instance: ReactInboxEventListener by lazy { ReactInboxEventListener() }
    }
}

/**
 * No-op inbox listener used to clear the forwarder from the SDK. Returning `false` from
 * [messageActionTaken] restores the SDK's default action handling. The native
 * `setInboxEventListener` API is non-null, so a no-op is installed rather than clearing.
 */
internal object NoOpInboxEventListener : InboxEventListener {
    override fun messageActionTaken(
        message: InboxMessage,
        actionName: String,
        actionValue: String,
    ): Boolean = false
}
