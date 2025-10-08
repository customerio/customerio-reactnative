package io.customer.reactnative.sdk.logging

import com.facebook.react.bridge.ReactApplicationContext
import io.customer.reactnative.sdk.NativeCustomerIOLoggingSpec
import io.customer.reactnative.sdk.util.onlyForLegacyArch

/**
 * React Native module implementation for Customer.io Logging Native SDK
 * using TurboModules with new architecture.
 *
 * Note: This module is not instantiated on armeabi-v7a architectures to prevent
 * TurboModule EventEmitter crashes. See CustomerIOReactNativePackageImpl for details.
 */
class NativeCustomerIOLoggingModule(
    reactContext: ReactApplicationContext,
) : NativeCustomerIOLoggingSpec(reactContext) {
    override fun getName(): String = NativeCustomerIOLoggingModuleImpl.NAME

    override fun initialize() {
        super.initialize()
        NativeCustomerIOLoggingModuleImpl.setLogEventEmitter { data ->
            emitOnCioLogEvent(data)
        }
    }

    override fun invalidate() {
        NativeCustomerIOLoggingModuleImpl.invalidate()
        super.invalidate()
    }

    override fun addListener(eventName: String?) {
        onlyForLegacyArch("addListener")
    }

    override fun removeListeners(count: Double) {
        onlyForLegacyArch("removeListeners")
    }
}
