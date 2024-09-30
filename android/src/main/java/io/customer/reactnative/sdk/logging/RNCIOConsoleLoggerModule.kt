package io.customer.reactnative.sdk.logging

import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactContextBaseJavaModule
import com.facebook.react.bridge.ReactMethod
import com.facebook.react.modules.core.DeviceEventManagerModule
import io.customer.sdk.core.di.SDKComponent
import io.customer.sdk.core.util.CioLogLevel

class RNCIOConsoleLoggerModule(
    private val reactContext: ReactApplicationContext,
) : ReactContextBaseJavaModule(reactContext) {
    override fun getName(): String = "CioLoggingEmitter"

    init {
        SDKComponent.logger.logDispatcher = { level, message ->
            emitLogEvent(level, message)
        }
    }

    private var listenerCount = 0

    @ReactMethod
    fun addListener(eventName: String) {
        listenerCount++
    }

    @ReactMethod
    fun removeListeners(count: Int) {
        listenerCount -= count
    }

    private fun emitLogEvent(level: CioLogLevel, message: String) {
        val data = buildMap {
            put("logLevel", level.name.lowercase())
            put("message", message)
        }
        val params = Arguments.makeNativeMap(data)
        reactContext
            .getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter::class.java)
            .emit("CioLogEvent", params)
    }
}
