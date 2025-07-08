package io.customer.reactnative.sdk.util

import io.customer.reactnative.sdk.BuildConfig

/**
 * Asserts that a value is non-null in debug builds.
 * Returns the value (even if null) in release builds to avoid crashing.
 */
inline fun <T : Any> assertNotNull(
    value: T?,
    lazyMessage: () -> String = { "Required value was null." }
): T? {
    return if (BuildConfig.DEBUG) {
        requireNotNull(value, lazyMessage)
    } else {
        value
    }
}
