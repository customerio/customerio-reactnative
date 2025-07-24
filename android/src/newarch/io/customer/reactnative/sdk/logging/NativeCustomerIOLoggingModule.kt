package io.customer.reactnative.sdk.logging

import com.facebook.react.bridge.Promise
import com.facebook.react.bridge.ReactApplicationContext
import io.customer.reactnative.sdk.NativeCustomerIOLoggingSpec
import io.customer.reactnative.sdk.util.onlyForLegacyArch

/**
 * React Native module implementation for Customer.io Logging Native SDK
 * using TurboModules with new architecture.
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

    override fun isNewArchEnabled(promise: Promise?) {
        promise?.resolve(true)
    }

    override fun addListener(eventName: String?) {
        onlyForLegacyArch("addListener")
    }

    override fun removeListeners(count: Double) {
        onlyForLegacyArch("removeListeners")
    }
}
