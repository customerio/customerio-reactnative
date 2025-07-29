package io.customer.reactnative.sdk.util

import io.customer.reactnative.sdk.BuildConfig
import io.customer.sdk.core.di.SDKComponent

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

/**
 * Throws a runtime exception in debug builds and logs a warning in release builds if a method
 * that is only supported on iOS is called from Android.
 *
 * Use this to guard any platform-specific methods that are not expected to run on Android.
 */
fun unsupportedOnAndroid(methodName: String) {
    val message = "'$methodName' is unsupported on Android and should not be called."

    if (BuildConfig.DEBUG) {
        error(message)
    } else {
        SDKComponent.logger.error(message)
    }
}
