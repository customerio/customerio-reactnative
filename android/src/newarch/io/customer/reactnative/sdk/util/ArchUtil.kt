package io.customer.reactnative.sdk.util

import io.customer.reactnative.sdk.BuildConfig
import io.customer.sdk.core.di.SDKComponent

/**
 * Marks a method that's only implemented for legacy architecture support.
 * Throws in debug; logs an error in release builds.
 */
fun onlyForLegacyArch(methodName: String) {
    val message = "'$methodName' is not required in the New Architecture and should not be called."

    if (BuildConfig.DEBUG) {
        error(message)
    } else {
        SDKComponent.logger.error(message)
    }
}
