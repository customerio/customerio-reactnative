package io.customer.reactnative.sdk.logging

import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactContextBaseJavaModule
import com.facebook.react.bridge.ReactMethod
import com.facebook.react.modules.core.DeviceEventManagerModule
import io.customer.sdk.core.di.SDKComponent
import io.customer.sdk.core.util.CioLogLevel
import java.lang.ref.WeakReference

class RNCIOConsoleLoggerModule(
    reactContext: ReactApplicationContext,
) : ReactContextBaseJavaModule(reactContext) {
    override fun getName(): String = "CioLoggingEmitter"

    // Hold weak reference to ReactContext to avoid memory leaks
    // As loggers are long-lived objects, they might hold references to log dispatchers
    // and can cause memory leaks by holding references to ReactContext even after it is destroyed
    private val contextRef = WeakReference(reactContext)

    init {
        SDKComponent.logger.setLogDispatcher { level, message ->
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
        val context = contextRef.get()
        if (context == null) {
            // If context is null, clear log dispatcher to stop listening to log events
            SDKComponent.logger.setLogDispatcher(null)
            return
        }

        val data = buildMap {
            put("logLevel", level.name.lowercase())
            put("message", message)
        }
        val params = Arguments.makeNativeMap(data)
        context
            .getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter::class.java)
            .emit("CioLogEvent", params)
    }
}
