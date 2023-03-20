package io.customer.reactnative.sdk.extension

import androidx.core.os.bundleOf
import com.facebook.react.bridge.ReadableMap
import com.google.firebase.messaging.RemoteMessage
import io.customer.sdk.data.model.Region
import io.customer.sdk.util.CioLogLevel

internal fun ReadableMap?.toMap(): Map<String, Any> {
    return this?.toHashMap() ?: emptyMap()
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

internal fun ReadableMap.toFCMRemoteMessage(): RemoteMessage {
    val cioParams = mutableListOf<Pair<String, Any>>()
    val googleParams = mutableListOf<Pair<String, Any>>()
    for ((key, value) in this.entryIterator) {
        when (key) {
            "data" -> {
                val dataMap = value as ReadableMap
                for (dataMapEntry in dataMap.entryIterator) {
                    cioParams.add(dataMapEntry.key to dataMapEntry.value)
                }
            }
            "from" -> googleParams.add(key to value)
            else -> googleParams.add(key.asGoogleParamKey() to value)
        }
    }
    val bundle = bundleOf(*googleParams.toTypedArray(), *cioParams.toTypedArray())
    return RemoteMessage(bundle)
}

private fun String.asGoogleParamKey(): String = "google.${this.camelToSnakeCase()}"
