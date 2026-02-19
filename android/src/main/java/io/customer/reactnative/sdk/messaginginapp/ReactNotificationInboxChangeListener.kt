package io.customer.reactnative.sdk.messaginginapp

import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.ReadableMap
import io.customer.messaginginapp.gist.data.model.InboxMessage
import io.customer.messaginginapp.inbox.NotificationInboxChangeListener

class ReactNotificationInboxChangeListener private constructor() : NotificationInboxChangeListener {

    // Event emitter function to send events to React Native layer
    private var eventEmitter: ((ReadableMap) -> Unit)? = null

    // Sets the event emitter function and message converter
    internal fun setEventEmitter(emitter: ((ReadableMap) -> Unit)?) {
        this.eventEmitter = emitter
    }

    // Clears the event emitter to prevent memory leaks
    internal fun clearEventEmitter() {
        this.eventEmitter = null
    }

    private fun emitMessagesUpdate(messages: List<InboxMessage>) {
        // Get the emitter and converter, return early if not set
        val emitter = eventEmitter ?: return

        val messagesArray = Arguments.createArray()
        messages.forEach { message ->
            messagesArray.pushMap(message.toWritableMap())
        }

        val payload = Arguments.createMap().apply {
            putArray("messages", messagesArray)
        }

        emitter.invoke(payload)
    }

    override fun onMessagesChanged(messages: List<InboxMessage>) {
        emitMessagesUpdate(messages)
    }

    companion object {
        // Singleton instance with public visibility for direct access
        val instance: ReactNotificationInboxChangeListener by lazy { ReactNotificationInboxChangeListener() }
    }
}
