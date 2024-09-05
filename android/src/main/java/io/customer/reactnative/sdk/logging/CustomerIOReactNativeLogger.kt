package io.customer.reactnative.sdk.logging
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactContextBaseJavaModule
import com.facebook.react.bridge.ReactMethod
import com.facebook.react.modules.core.DeviceEventManagerModule

class CioLoggingEmitter(reactContext: ReactApplicationContext) : ReactContextBaseJavaModule(reactContext) {

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


