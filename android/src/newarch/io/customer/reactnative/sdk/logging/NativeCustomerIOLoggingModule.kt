package io.customer.reactnative.sdk.logging

import com.facebook.react.bridge.ReactApplicationContext
import io.customer.reactnative.sdk.NativeCustomerIOLoggingSpec
import io.customer.reactnative.sdk.util.isRunningOnArmeabiABI
import io.customer.reactnative.sdk.util.logUnsupportedAbi
import io.customer.reactnative.sdk.util.onlyForLegacyArch
import io.customer.reactnative.sdk.util.runIfAbiSupported
import io.customer.reactnative.sdk.util.runWithTryCatch

/**
 * React Native module implementation for Customer.io Logging Native SDK
 * using TurboModules with new architecture.
 */
class NativeCustomerIOLoggingModule(
    reactContext: ReactApplicationContext,
) : NativeCustomerIOLoggingSpec(reactContext) {
    // Lazy property to check if the current ABI is supported (non-armeabi)
    // Cached to avoid repeated ABI checks
    private val isAbiSupported: Boolean by lazy { !isRunningOnArmeabiABI() }

    private fun runOnSupportedAbi(action: () -> Unit) {
        runIfAbiSupported(isSupported = isAbiSupported, action)
    }

    override fun initialize() {
        runWithTryCatch {
            super.initialize()
            if (!isAbiSupported) {
                logUnsupportedAbi()
            }
            runOnSupportedAbi {
                NativeCustomerIOLoggingModuleImpl.setLogEventEmitter { data ->
                    emitOnCioLogEvent(data)
                }
            }
        }
    }

    override fun invalidate() {
        runOnSupportedAbi {
            NativeCustomerIOLoggingModuleImpl.invalidate()
        }
        runWithTryCatch {
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
