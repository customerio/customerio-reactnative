package io.customer.reactnative.sdk.messaginginapp

import com.facebook.react.bridge.ReactApplicationContext
import io.customer.reactnative.sdk.NativeCustomerIOMessagingInAppSpec
import io.customer.reactnative.sdk.util.isRunningOnArmeabiABI
import io.customer.reactnative.sdk.util.logUnsupportedAbi
import io.customer.reactnative.sdk.util.onlyForLegacyArch
import io.customer.reactnative.sdk.util.runIfAbiSupported
import io.customer.reactnative.sdk.util.runWithTryCatch

/**
 * React Native module implementation for Customer.io In-App Messaging Native SDK
 * using TurboModules with new architecture.
 */
class NativeMessagingInAppModule(
    reactContext: ReactApplicationContext,
) : NativeCustomerIOMessagingInAppSpec(reactContext) {
    private val inAppEventListener: ReactInAppEventListener
        get() = NativeMessagingInAppModuleImpl.inAppEventListener

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
                inAppEventListener.setEventEmitter { data ->
                    emitOnInAppEventReceived(data)
                }
            }
        }
    }

    override fun invalidate() {
        runOnSupportedAbi {
            inAppEventListener.clearEventEmitter()
        }
        runWithTryCatch {
            super.invalidate()
        }
    }

    override fun dismissMessage() {
        runOnSupportedAbi {
            NativeMessagingInAppModuleImpl.dismissMessage()
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
