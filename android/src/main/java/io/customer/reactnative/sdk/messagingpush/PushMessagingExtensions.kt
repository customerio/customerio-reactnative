package io.customer.reactnative.sdk.messagingpush

import com.facebook.react.bridge.ReadableMap
import com.google.firebase.messaging.RemoteMessage
import io.customer.reactnative.sdk.extension.toMap

/**
 * Safely transforms any value to string
 */
private fun Any.toStringOrNull(): String? = try {
    toString()
} catch (ex: Exception) {
    // We don't need to print any error here as this is expected for some values and doesn't
    // break anything
    null
}

/**
 * Extension function to build FCM [RemoteMessage] using RN map. This should be independent from
 * the sender source and should be able to build a valid [RemoteMessage] for our native SDK.
 *
 * @param destination receiver of the message. It is mainly required for sending upstream messages,
 * since we are using RemoteMessage only for broadcasting messages locally, we can use any non-empty
 * string for it.
 */
internal fun ReadableMap.toFCMRemoteMessage(destination: String): RemoteMessage {
    val messageParams = buildMap {
        putAll(getMap("notification").toMap())
        // Adding `data` after `notification` so `data` params take more value as we mainly use
        // `data` in rich push
        putAll(getMap("data").toMap())
    }
    return with(RemoteMessage.Builder(destination)) {
        messageParams.let { params ->
            val paramsIterator = params.iterator()
            while (paramsIterator.hasNext()) {
                val (key, value) = paramsIterator.next()
                // Some values in notification object can be another object and may not support
                // mapping to string values, transforming these values in a try-catch so the code
                // doesn't break due to one bad value
                value.toStringOrNull()?.let { v -> addData(key, v) }
            }
        }
        getString("messageId")?.let { id -> setMessageId(id) }
        getString("messageType")?.let { type -> setMessageType(type) }
        getString("collapseKey")?.let { key -> setCollapseKey(key) }
        if (hasKey("ttl")) {
            ttl = getInt("ttl")
        }
        build()
    }
}
