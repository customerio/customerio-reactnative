package io.customer.reactnative.sdk.logging

import android.util.Log
import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReadableMap
import io.customer.reactnative.sdk.NativeCustomerIOLoggingSpec
import io.customer.sdk.core.di.SDKComponent
import io.customer.sdk.core.util.CioLogLevel

/**
 * React Native module implementation for Customer.io Logging Native SDK
 * using TurboModules with new architecture.
 */
class NativeCustomerIOLoggingModule(
    reactContext: ReactApplicationContext,
) : NativeCustomerIOLoggingSpec(reactContext) {
    override fun getName(): String = NAME

    // Log event emitter function to send events to React Native layer
    private var logEventEmitter: ((ReadableMap) -> Unit)? = null

    /**
     * Executes the given block and logs any uncaught exceptions using Android logger to protect
     * against unexpected crashes and failures.
     */
    private fun runWithTryCatch(action: () -> Unit) {
        try {
            action()
        } catch (ex: Exception) {
            // Use Android logger to avoid cyclic calls from internal SDK logging
            Log.e("[CIO]", "Error in NativeCustomerIOLoggingModule: ${ex.message}", ex)
        }
    }

    override fun initialize() {
        runWithTryCatch {
            super.initialize()
            setLogEventEmitter { data ->
                emitOnCioLogEvent(data)
            }
        }
    }

    override fun invalidate() {
        runWithTryCatch {
            cleanupLogEventEmitter()
            super.invalidate()
        }
    }

    private fun cleanupLogEventEmitter() {
        runWithTryCatch {
            // Clear log dispatcher to prevent memory leaks and further events
            SDKComponent.logger.setLogDispatcher(null)
            this.logEventEmitter = null
        }
    }

    // Sets the event emitter function used to send log events to React Native.
    private fun setLogEventEmitter(emitter: ((ReadableMap) -> Unit)?) {
        if (emitter == null) {
            // Clear log dispatcher if emitter is null
            cleanupLogEventEmitter()
            return
        }

        SDKComponent.logger.setLogDispatcher { level, message ->
            emitLogEvent(level, message)
        }
        this.logEventEmitter = emitter
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

    companion object {
        internal const val NAME = "NativeCustomerIOLogging"
    }
}
