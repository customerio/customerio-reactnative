package io.customer.reactnative.sdk.logging

import com.facebook.react.bridge.Promise
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactContextBaseJavaModule
import com.facebook.react.bridge.ReactMethod
import com.facebook.react.modules.core.DeviceEventManagerModule

/**
 * React Native module implementation for Customer.io Logging Native SDK
 * using legacy architecture.
 */
class NativeCustomerIOLoggingModule(
    private val reactContext: ReactApplicationContext,
) : ReactContextBaseJavaModule(reactContext) {
    override fun getName(): String = NativeCustomerIOLoggingModuleImpl.NAME

    private var listenerCount = 0

    override fun initialize() {
        super.initialize()
        NativeCustomerIOLoggingModuleImpl.setLogEventEmitter { data ->
            if (listenerCount <= 0) return@setLogEventEmitter

            reactContext
                .getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter::class.java)
                .emit("CioLogEvent", data)
        }
    }

    override fun invalidate() {
        NativeCustomerIOLoggingModuleImpl.invalidate()
        super.invalidate()
    }

    @ReactMethod
    fun isNewArchEnabled(promise: Promise?) {
        promise?.resolve(false)
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
