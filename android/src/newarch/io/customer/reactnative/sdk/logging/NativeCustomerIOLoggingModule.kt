package io.customer.reactnative.sdk.logging

import android.util.Log
import com.facebook.react.bridge.ReactApplicationContext
import io.customer.reactnative.sdk.NativeCustomerIOLoggingSpec

/**
 * React Native module implementation for Customer.io Logging Native SDK
 * using TurboModules with new architecture.
 */
class NativeCustomerIOLoggingModule(
    reactContext: ReactApplicationContext,
) : NativeCustomerIOLoggingSpec(reactContext) {
    override fun getName(): String = NativeCustomerIOLoggingModuleImpl.NAME

    /**
     * Executes the given block and logs any uncaught exceptions using Android logger to protect
     * against unexpected crashes and failures.
     */
    private fun runWithTryCatch(action: () -> Unit) {
        try {
            action()
        } catch (ex: Exception) {
            // Use Android logger to avoid cyclic calls from internal SDK logging
            Log.e("[CIO]", "Error in NativeCustomerIOLoggingModule: ${ex.message}", ex)
        }
    }

    override fun initialize() {
        runWithTryCatch {
            super.initialize()
            NativeCustomerIOLoggingModuleImpl.setLogEventEmitter { data ->
                emitOnCioLogEvent(data)
            }
        }
    }

    override fun invalidate() {
        runWithTryCatch {
            NativeCustomerIOLoggingModuleImpl.invalidate()
        }
        runWithTryCatch {
            super.invalidate()
        }
    }
}
