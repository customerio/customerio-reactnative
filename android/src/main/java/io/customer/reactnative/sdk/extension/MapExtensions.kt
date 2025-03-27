package io.customer.reactnative.sdk.extension

import com.facebook.react.bridge.ReadableMap

internal fun ReadableMap?.toMap(): Map<String, Any> {
    return this?.toHashMap()?.filterValues { it != null }?.mapValues { it.value as Any } ?: emptyMap()
}

internal inline fun <reified V> Map<String, Any?>?.getTypedValue(key: String): V? {
    return this?.get(key) as? V
}
