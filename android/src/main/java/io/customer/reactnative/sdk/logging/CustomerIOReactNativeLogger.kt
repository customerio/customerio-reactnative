package io.customer.reactnative.sdk.logging
import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactContextBaseJavaModule
import com.facebook.react.bridge.ReactMethod
import com.facebook.react.module.annotations.ReactModule
import com.facebook.react.modules.core.DeviceEventManagerModule
import io.customer.sdk.core.util.CioLogLevel
import io.customer.sdk.core.util.Logger
import kotlin.collections.buildMap

@ReactModule(name = CustomerIOReactNativeLoggingEmitter.NAME)
class CustomerIOReactNativeLoggingEmitter(
    private val reactContext: ReactApplicationContext,
) : ReactContextBaseJavaModule(reactContext) {
    companion object {
        const val EVENT_NAME = "CioLogEvent"
        const val NAME = "CioLoggingEmitter"

    }
    private var listenerCount = 0

    override fun getName(): String {
        return NAME
    }

    @ReactMethod
    fun addListener(eventName: String) {
        listenerCount++
    }

    @ReactMethod
    fun removeListeners(count: Int) {
        listenerCount -= count
    }

    // Not in use currently, check if we need it or not
    // If not then remove EVENT_NAME as well 
    fun sendEvent(eventName: String, params: String) {
        println("I got control here")
        reactContext
            .getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter::class.java)
            .emit(EVENT_NAME, params)
    }
}

class CustomerIOReactNativeLoggingWrapper private constructor(
    private var moduleRegistry: ReactApplicationContext,
    override var logLevel: CioLogLevel): Logger {

    companion object {
        fun getInstance(moduleRegistry: ReactApplicationContext, logLevel: CioLogLevel): CustomerIOReactNativeLoggingWrapper {
            val instance = CustomerIOReactNativeLoggingWrapper(moduleRegistry, logLevel)
//            DIGraphShared.shared.override(instance, CioLogger::class.java)
            return instance
        }
    }

    override fun debug(message: String) {
        println("Hello, debug!")
        emit(message, CioLogLevel.DEBUG)
    }

    override fun info(message: String) {
        println("Hello, info!")
        emit(message, CioLogLevel.INFO)
    }

    override fun error(message: String) {
        println("Hello, error!")
        emit(message, CioLogLevel.ERROR)
    }

    private fun emit(message: String, level: CioLogLevel) {
        println("Hello, Emit!")
        if (shouldEmit(level)) {

            val data = buildMap {
                put("logLevel", "info")
                put("message", message)
            }

            moduleRegistry
                .getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter::class.java)
                .emit("CioLogEvent", Arguments.makeNativeMap(data))
        }
    }

    private fun shouldEmit(level: CioLogLevel): Boolean {
        println("Hello, shouldEmit!")
        return when (logLevel) {
            CioLogLevel.NONE -> false
            CioLogLevel.ERROR -> level == CioLogLevel.ERROR
            CioLogLevel.INFO -> level == CioLogLevel.ERROR || level == CioLogLevel.INFO
            CioLogLevel.DEBUG -> true
        }
    }

}