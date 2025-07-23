package io.customer.reactnative.sdk.messaginginapp

import com.facebook.react.bridge.Promise
import com.facebook.react.bridge.ReactApplicationContext
import io.customer.reactnative.sdk.NativeCustomerIOMessagingInAppSpec
import io.customer.reactnative.sdk.util.onlyForLegacyArch

/**
 * React Native module implementation for Customer.io In-App Messaging Native SDK
 * using TurboModules with new architecture.
 */
class NativeMessagingInAppModule(
    reactContext: ReactApplicationContext,
) : NativeCustomerIOMessagingInAppSpec(reactContext) {
    private val inAppEventListener: ReactInAppEventListener
        get() = NativeMessagingInAppModuleImpl.inAppEventListener

    override fun initialize() {
        super.initialize()
        inAppEventListener.setEventEmitter { data ->
            emitOnInAppEventReceived(data)
        }
    }

    override fun invalidate() {
        inAppEventListener.clearEventEmitter()
        super.invalidate()
    }

    override fun dismissMessage() {
        NativeMessagingInAppModuleImpl.dismissMessage()
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
