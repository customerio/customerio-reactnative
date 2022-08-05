package io.customer.reactnative.sdk

import com.facebook.react.bridge.ReadableMap
import io.customer.sdk.data.model.Region
import io.customer.sdk.util.CioLogLevel

internal fun ReadableMap?.toMap(): Map<String, Any> {
    return this?.toHashMap() ?: emptyMap()
}

internal fun String?.toRegion(): Region? {
    return if (this.isNullOrBlank()) null
    else listOf(
        Region.US,
        Region.EU,
    ).find { value -> value.code.equals(this, ignoreCase = true) }
}

internal fun Int.toCIOLogLevel(): CioLogLevel? {
    return CioLogLevel.values().getOrNull(index = this)
}

internal fun String?.withLogsPrefix(): String = "[ReactNativeBridge]: $this"

@Throws(IllegalArgumentException::class)
internal inline fun <reified T> Map<String, Any>.getReactPropertyUnsafe(key: String): T? {
    val property = get(key) ?: return null

    if (property !is T) {
        throw IllegalArgumentException(
            "Invalid value provided for key: $key, must be of type ${T::class.java.simpleName}"
        )
    }
    return property
}
