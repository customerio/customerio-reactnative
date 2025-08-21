package io.customer.reactnative.sdk.logging

import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.ReadableMap
import io.customer.sdk.core.di.SDKComponent
import io.customer.sdk.core.util.CioLogLevel

/**
 * Shared implementation for Customer.io Logging Native SDK module.
 * Handles log event dispatching from the native SDK to React Native layer.
 * Contains the actual business logic used by both new and old architecture modules.
 */
object NativeCustomerIOLoggingModuleImpl {
    const val NAME = "NativeCustomerIOLogging"

    // Log event emitter function to send events to React Native layer
    private var logEventEmitter: ((ReadableMap) -> Unit)? = null

    // Sets the event emitter function used to send log events to React Native.
    internal fun setLogEventEmitter(emitter: ((ReadableMap) -> Unit)?) {
        // Set up log dispatcher only when first emitter is set
        if (emitter != null && logEventEmitter == null) {
            SDKComponent.logger.setLogDispatcher { level, message ->
                emitLogEvent(level, message)
            }
        }
        
        this.logEventEmitter = emitter
    }

    // Clears the event emitter, should be called during module cleanup
    internal fun invalidate() {
        // Clear log dispatcher to prevent memory leaks and further events
        SDKComponent.logger.setLogDispatcher(null)
        this.logEventEmitter = null
    }

    // Converts native SDK log events to React Native compatible format and emits them.
    private fun emitLogEvent(level: CioLogLevel, message: String) {
        // Defensive check: only emit if emitter is available
        val emitter = logEventEmitter ?: return
        
        val data = buildMap {
            put("logLevel", level.name.lowercase())
            put("message", message)
        }

        emitter.invoke(Arguments.makeNativeMap(data))
    }
}
