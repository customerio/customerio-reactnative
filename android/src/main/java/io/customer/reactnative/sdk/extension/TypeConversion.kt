package io.customer.reactnative.sdk.extension

import com.facebook.react.bridge.ReadableMap
import com.google.firebase.messaging.RemoteMessage
import io.customer.sdk.data.model.Region
import io.customer.sdk.util.CioLogLevel

internal fun ReadableMap?.toMap(): Map<String, Any> {
    return this?.toHashMap() ?: emptyMap()
}

internal fun ReadableMap.toMutableStringMap(): MutableMap<String, String?> {
    return this.toHashMap().mapValues { toString() }.toMutableMap()
}

internal fun String?.toRegion(fallback: Region = Region.US): Region {
    return if (this.isNullOrBlank()) fallback
    else listOf(
        Region.US,
        Region.EU,
    ).find { value -> value.code.equals(this, ignoreCase = true) } ?: fallback
}

internal fun Double?.toCIOLogLevel(fallback: CioLogLevel = CioLogLevel.NONE): CioLogLevel {
    return if (this == null) fallback
    else CioLogLevel.values().getOrNull(index = toInt() - 1) ?: fallback
}

/**
 * Extensions function to build FCM [RemoteMessage] using RN map. This should be independent from
 * the sender source and should be able to build a valid [RemoteMessage] for our native SDK.
 *
 * @param destination receiver of the message. It is mainly required for sending upstream messages,
 * since we are using RemoteMessage only for broadcasting messages locally, we can use any non-empty
 * string for it.
 */
internal fun ReadableMap.toFCMRemoteMessage(destination: String): RemoteMessage {
    return with(RemoteMessage.Builder(destination)) {
        getMap("data")?.toMutableStringMap()?.let { data -> setData(data) }
        getString("messageId")?.let { id -> setMessageId(id) }
        getString("messageType")?.let { type -> setMessageType(type) }
        getString("collapseKey")?.let { key -> setCollapseKey(key) }
        if (hasKey("ttl")) {
            ttl = getInt("ttl")
        }
        build()
    }
}
