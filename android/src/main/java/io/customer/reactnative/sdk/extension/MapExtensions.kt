package io.customer.reactnative.sdk.extension

import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.ReadableMap
import com.facebook.react.bridge.WritableArray
import com.facebook.react.bridge.WritableMap

// Converts ReadableMap to Kotlin Map, filtering out null values.
internal fun ReadableMap?.toMap(): Map<String, Any> {
    return this?.toHashMap()?.filterValues {
        it != null
    }?.mapValues { it.value as Any } ?: emptyMap()
}

// Retrieves a typed value from the map using reified type parameter.
internal inline fun <reified V> Map<String, Any?>?.getTypedValue(key: String): V? {
    return this?.get(key) as? V
}

/**
 * Converts Kotlin Map to WritableMap for React Native, handling nested maps/arrays recursively.
 * Long values are converted to Double since JavaScript doesn't have type Long.
 */
internal fun Map<String, Any?>.toWritableMap(): WritableMap {
    val writableMap = Arguments.createMap()

    for ((key, value) in this) {
        when (value) {
            null -> writableMap.putNull(key)
            is String -> writableMap.putString(key, value)
            is Int -> writableMap.putInt(key, value)
            is Double -> writableMap.putDouble(key, value)
            is Float -> writableMap.putDouble(key, value.toDouble())
            is Boolean -> writableMap.putBoolean(key, value)
            is Long -> writableMap.putDouble(key, value.toDouble()) // JS has no Long
            is Map<*, *> -> {
                @Suppress("UNCHECKED_CAST")
                writableMap.putMap(key, (value as Map<String, Any?>).toWritableMap())
            }

            is List<*> -> writableMap.putArray(key, value.toWritableArray())
            else -> {
                // Fallback — convert to string
                writableMap.putString(key, value.toString())
            }
        }
    }

    return writableMap
}

/**
 * Converts Kotlin List to WritableArray for React Native, handling nested lists/maps recursively.
 * Long values are converted to Double since JavaScript doesn't have type Long.
 */
internal fun List<*>.toWritableArray(): WritableArray {
    val writableArray = Arguments.createArray()

    for (value in this) {
        when (value) {
            null -> writableArray.pushNull()
            is String -> writableArray.pushString(value)
            is Int -> writableArray.pushInt(value)
            is Double -> writableArray.pushDouble(value)
            is Float -> writableArray.pushDouble(value.toDouble())
            is Boolean -> writableArray.pushBoolean(value)
            is Long -> writableArray.pushDouble(value.toDouble())
            is Map<*, *> -> {
                @Suppress("UNCHECKED_CAST")
                writableArray.pushMap((value as Map<String, Any?>).toWritableMap())
            }

            is List<*> -> writableArray.pushArray(value.toWritableArray())
            else -> writableArray.pushString(value.toString())
        }
    }

    return writableArray
}

// Puts a value into WritableMap, calling putNull if value is null, otherwise executing putBlock.
internal inline fun <T> WritableMap.putOrNull(
    key: String,
    value: T?,
    putBlock: WritableMap.(String, T) -> Unit,
) {
    if (value == null) {
        putNull(key)
    } else {
        putBlock(key, value)
    }
}
