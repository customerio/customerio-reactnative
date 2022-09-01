package io.customer.reactnative.sdk.util

import android.util.Log
import io.customer.sdk.util.CioLogLevel
import io.customer.sdk.util.Logger

internal class ReactNativeConsoleLogger(
    internal var logLevel: CioLogLevel
) : Logger {
    private fun runIfMeetsLogLevelCriteria(levelForMessage: CioLogLevel, block: () -> Unit) {
        val shouldLog = logLevel.shouldLog(levelForMessage)

        if (shouldLog) block()
    }

    override fun info(message: String) {
        runIfMeetsLogLevelCriteria(CioLogLevel.INFO) {
            Log.i(TAG, message)
        }
    }

    override fun debug(message: String) {
        runIfMeetsLogLevelCriteria(CioLogLevel.DEBUG) {
            Log.d(TAG, message)
        }
    }

    override fun error(message: String) {
        runIfMeetsLogLevelCriteria(CioLogLevel.ERROR) {
            Log.e(TAG, message)
        }
    }

    companion object {
        private const val TAG = "[CIO]-[RN]"
    }
}
