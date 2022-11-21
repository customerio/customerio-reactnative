package io.customer.reactnative.sdk.extension

import io.customer.sdk.CustomerIOShared

@Throws(IllegalArgumentException::class)
internal inline fun <reified T> Map<String, Any?>.getPropertyUnsafe(key: String): T {
    val property = get(key)

    if (property !is T) {
        throw IllegalArgumentException(
            "Invalid value provided for key: $key, value $property must be of type ${T::class.java.simpleName}"
        )
    }
    return property
}

internal inline fun <reified T> Map<String, Any?>.getProperty(key: String): T? = try {
    getPropertyUnsafe(key)
} catch (ex: IllegalArgumentException) {
    CustomerIOShared.instance().diStaticGraph.logger.error(
        ex.message ?: "getProperty($key) -> IllegalArgumentException"
    )
    null
}

@Throws(IllegalArgumentException::class)
internal fun Map<String, Any?>.getString(key: String): String = try {
    getPropertyUnsafe<String>(key).takeIfNotBlank() ?: throw IllegalArgumentException(
        "Invalid value provided for $key, must not be blank"
    )
} catch (ex: IllegalArgumentException) {
    CustomerIOShared.instance().diStaticGraph.logger.error(
        ex.message ?: "getString($key) -> IllegalArgumentException"
    )
    throw ex
}
