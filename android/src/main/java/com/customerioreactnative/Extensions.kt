package com.customerioreactnative

import com.facebook.react.bridge.ReadableMap
import io.customer.sdk.data.model.Region

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
