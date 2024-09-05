package io.customer.reactnative.sdk.logging
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactContextBaseJavaModule
import com.facebook.react.bridge.ReactMethod
import com.facebook.react.modules.core.DeviceEventManagerModule
import io.customer.sdk.core.di.SDKComponent
import io.customer.sdk.core.util.CioLogLevel
import io.customer.sdk.core.util.Logger

class CustomerIOReactNativeLoggingEmitter(reactContext: ReactApplicationContext) : ReactContextBaseJavaModule(reactContext) {

    companion object {
        const val EVENT_NAME = "CioLogEvent"
    }

    private var hasObservers = false

    override fun getName(): String {
        return "CioLoggingEmitter"
    }

    override fun initialize() {
        hasObservers = true
    }

    override fun onCatalystInstanceDestroy() {
        hasObservers = false
    }

    @ReactMethod
    fun startObserving() {
        hasObservers = true
    }

    @ReactMethod
    fun stopObserving() {
        hasObservers = false
    }

    override fun getConstants(): MutableMap<String, Any> {
        return hashMapOf("supportedEvents" to listOf(EVENT_NAME))
    }

    fun sendEvent(logLevel: String, message: String) {
        if (hasObservers) {
            reactApplicationContext
                .getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter::class.java)
                .emit(EVENT_NAME, mapOf("logLevel" to logLevel, "message" to message))
        }
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

//    fun setLogLevel(level: CioLogLevel) {
//        logLevel = level
//    }

    override fun debug(message: String) {
        emit(message, CioLogLevel.DEBUG)
    }

    override fun info(message: String) {
        emit(message, CioLogLevel.INFO)
    }

    override fun error(message: String) {
        emit(message, CioLogLevel.ERROR)
    }

    private fun emit(message: String, level: CioLogLevel) {
        if (shouldEmit(level)) {
            val emitter = moduleRegistry.getNativeModule(CustomerIOReactNativeLoggingEmitter::class.java)
            emitter?.sendEvent(level.name, message)
        }
    }

    private fun shouldEmit(level: CioLogLevel): Boolean {
        return when (logLevel) {
            CioLogLevel.NONE -> false
            CioLogLevel.ERROR -> level == CioLogLevel.ERROR
            CioLogLevel.INFO -> level == CioLogLevel.ERROR || level == CioLogLevel.INFO
            CioLogLevel.DEBUG -> true
        }
    }

}