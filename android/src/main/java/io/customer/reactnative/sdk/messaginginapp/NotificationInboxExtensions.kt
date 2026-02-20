package io.customer.reactnative.sdk.messaginginapp

import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.WritableMap
import io.customer.messaginginapp.gist.data.model.InboxMessage
import io.customer.reactnative.sdk.extension.putOrNull
import io.customer.reactnative.sdk.extension.toWritableArray
import io.customer.reactnative.sdk.extension.toWritableMap

// Converts an [InboxMessage] to a [WritableMap] for React Native bridge
internal fun InboxMessage.toWritableMap(): WritableMap {
    return Arguments.createMap().apply {
        putString("queueId", queueId)
        putOrNull("deliveryId", deliveryId) { k, v -> putString(k, v) }
        putDouble("sentAt", sentAt.time.toDouble())
        putOrNull("expiry", expiry) { k, v -> putDouble(k, v.time.toDouble()) }
        putString("type", type)
        putBoolean("opened", opened)
        putArray("topics", topics.toWritableArray())
        putOrNull("priority", priority) { k, v -> putInt(k, v) }
        putMap("properties", properties.toWritableMap())
    }
}
