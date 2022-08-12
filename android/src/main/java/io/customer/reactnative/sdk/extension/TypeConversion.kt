package io.customer.reactnative.sdk.extension

import com.facebook.react.bridge.ReadableMap
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
    else CioLogLevel.values().getOrNull(index = this.toInt()) ?: fallback
}
