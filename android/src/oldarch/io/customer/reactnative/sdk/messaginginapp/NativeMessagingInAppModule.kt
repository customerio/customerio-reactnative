package io.customer.reactnative.sdk.messaginginapp

import com.facebook.react.bridge.Promise
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactContextBaseJavaModule
import com.facebook.react.bridge.ReactMethod
import com.facebook.react.modules.core.DeviceEventManagerModule

/**
 * React Native module implementation for Customer.io In-App Messaging Native
 * SDK using old architecture.
 */
class NativeMessagingInAppModule(
    private val reactContext: ReactApplicationContext,
) : ReactContextBaseJavaModule(reactContext) {
    override fun getName(): String = NativeMessagingInAppModuleImpl.NAME

    private var listenerCount = 0
    private val inAppEventListener: ReactInAppEventListener
        get() = NativeMessagingInAppModuleImpl.inAppEventListener

    override fun initialize() {
        super.initialize()
        inAppEventListener.setEventEmitter { data ->
            if (listenerCount <= 0) return@setEventEmitter

            reactContext
                .getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter::class.java)
                .emit("InAppEventListener", data)
        }
    }

    override fun invalidate() {
        inAppEventListener.clearEventEmitter()
        super.invalidate()
    }

    @ReactMethod
    fun dismissMessage() {
        NativeMessagingInAppModuleImpl.dismissMessage()
    }

    @ReactMethod
    fun addListener(eventName: String?) {
        listenerCount++
    }

    @ReactMethod
    fun removeListeners(count: Double) {
        listenerCount -= count.toInt()
    }
}
