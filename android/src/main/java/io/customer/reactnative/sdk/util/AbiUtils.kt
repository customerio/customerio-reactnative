package io.customer.reactnative.sdk.util

import android.os.Build
import android.util.Log
import com.facebook.react.bridge.NativeModule

/**
 * Checks if the app is running on armeabi or armeabi-v7a ABI architecture.
 * Returns true if the most preferred ABI (first in SUPPORTED_ABIS) is armeabi-based.
 */
internal fun isRunningOnArmeabiABI(): Boolean {
    return Build.SUPPORTED_ABIS?.firstOrNull()
        ?.lowercase()
        ?.contains("armeabi") == true
}

/**
 * Logs a message indicating that the native module is disabled on unsupported ABI.
 * Should be called when a module detects it's running on an unsupported ABI.
 */
internal fun NativeModule.logUnsupportedAbi() {
    Log.i(
        "[CIO]",
        "[$name] Native module is disabled on armeabi/armeabi-v7a ABI to avoid native crashes (Supported ABIs: ${Build.SUPPORTED_ABIS?.joinToString()})"
    )
}

/**
 * Executes the given block and logs any uncaught exceptions using Android logger to protect
 * against unexpected crashes and failures.
 * Automatically includes the module name in error logs for easier debugging.
 */
internal fun NativeModule.runWithTryCatch(action: () -> Unit) {
    try {
        action()
    } catch (ex: Exception) {
        // Use Android logger to avoid cyclic calls from internal SDK logging
        Log.e("[CIO]", "[$name] Error in React Native module: ${ex.message}", ex)
    }
}

/**
 * Executes the given action only if the ABI is supported.
 * Skips execution on unsupported ABIs (e.g., armeabi/armeabi-v7a) to prevent C++ crashes.
 * Automatically includes the module name in error logs for easier debugging.
 *
 * @param isSupported true if the current ABI supports the action, false otherwise
 * @param action the block to execute if the ABI is supported
 */
internal fun NativeModule.runIfAbiSupported(
    isSupported: Boolean,
    action: () -> Unit
) = runWithTryCatch {
    if (!isSupported) {
        // Skip execution on unsupported ABIs to avoid known native (C++) crashes.
        // This ensures stability on lower-end or legacy devices by preventing risky native calls.
        return@runWithTryCatch
    }

    action()
}
