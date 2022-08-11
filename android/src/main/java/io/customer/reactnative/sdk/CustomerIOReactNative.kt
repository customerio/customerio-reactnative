package io.customer.reactnative.sdk

import io.customer.reactnative.sdk.util.ReactNativeConsoleLogger
import io.customer.sdk.util.CioLogLevel
import io.customer.sdk.util.Logger

internal class CustomerIOReactNative(
    val logger: Logger,
) {

    internal companion object {
        private var instance: CustomerIOReactNative? = null

        @JvmStatic
        fun initialize(logLevel: CioLogLevel) {
            // Should never happen ideally as we are already making single call from the caller
            if (instance != null) return

            instance = CustomerIOReactNative(
                logger = ReactNativeConsoleLogger(logLevel = logLevel),
            )
        }

        fun instance(): CustomerIOReactNative {
            return instance ?: throw IllegalStateException(
                "Customer.io instance not initialized. " +
                        "Please call ${CustomerIOReactNativeModule.MODULE_NAME}::initialize() on app start"
            )
        }
    }
}
