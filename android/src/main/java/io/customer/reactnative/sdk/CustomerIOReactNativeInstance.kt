package io.customer.reactnative.sdk

import io.customer.reactnative.sdk.util.ReactNativeConsoleLogger
import io.customer.sdk.util.CioLogLevel
import io.customer.sdk.util.Logger

/**
 * Static property holder for ReactNative package to overcome SDK
 * initialization challenges
 */
object CustomerIOReactNativeInstance {
    internal val logger: Logger = ReactNativeConsoleLogger(CioLogLevel.ERROR)

    fun setLogLevel(logLevel: CioLogLevel) {
        (logger as ReactNativeConsoleLogger).logLevel = logLevel
    }
}
