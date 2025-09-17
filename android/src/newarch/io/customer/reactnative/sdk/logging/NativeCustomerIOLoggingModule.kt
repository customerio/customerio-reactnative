package io.customer.reactnative.sdk.logging

import android.os.Build
import android.util.Log
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

    // true if the app is currently running under armeabi/armeabi-v7a ABIs.
    // We check only the first ABI in SUPPORTED_ABIS because the first one is most preferred ABI.
    private val isABIArmeabi: Boolean by lazy {
        Build.SUPPORTED_ABIS.firstOrNull()?.contains("armeabi", ignoreCase = true) == true
    }

    /**
     * Executes the given action only if the current ABI supports it.
     * Skips execution on armeabi/armeabi-v7a to prevent C++ crashes on unsupported architectures.
     */
    private fun runOnSupportedAbi(action: () -> Unit) {
        try {
            if (isABIArmeabi) {
                // Skip execution on armeabi-v7a to avoid known native (C++) crashes on unsupported ABIs.
                // This is to ensures stability on lower-end or legacy devices by preventing risky native calls.
                return
            }
            action()
        } catch (ex: Exception) {
            // Use Android logger to avoid cyclic calls from internal SDK logging
            Log.e("[CIO]", "Error in NativeCustomerIOLoggingModule: ${ex.message}", ex)
        }
    }

    override fun initialize() {
        runOnSupportedAbi {
            super.initialize()
            NativeCustomerIOLoggingModuleImpl.setLogEventEmitter { data ->
                emitOnCioLogEvent(data)
            }
        }
    }

    override fun invalidate() {
        runOnSupportedAbi {
            NativeCustomerIOLoggingModuleImpl.invalidate()
            super.invalidate()
        }
    }

    override fun addListener(eventName: String?) {
        runOnSupportedAbi {
            onlyForLegacyArch("addListener")
        }
    }

    override fun removeListeners(count: Double) {
        runOnSupportedAbi {
            onlyForLegacyArch("removeListeners")
        }
    }
}
