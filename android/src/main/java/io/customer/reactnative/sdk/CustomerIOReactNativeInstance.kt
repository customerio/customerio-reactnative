package io.customer.reactnative.sdk

import io.customer.reactnative.sdk.util.ReactNativeConsoleLogger
import io.customer.sdk.util.CioLogLevel
import io.customer.sdk.util.Logger
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.withTimeoutOrNull
import java.util.concurrent.atomic.AtomicBoolean

/**
 * Static property holder for ReactNative package to overcome SDK
 * initialization challenges
 */
object CustomerIOReactNativeInstance {
    private const val SDK_INITIALIZATION_TIMEOUT_DURATION_DEFAULT = 5_000L

    internal val logger: Logger = ReactNativeConsoleLogger(CioLogLevel.ERROR)
    internal var cachedFCMToken: String? = null
    private val isFCMTokenRegistered = AtomicBoolean(false)

    private val initializationStateFlow = MutableStateFlow(value = false)
    private val initializationFlow = initializationStateFlow.asStateFlow()
        .filter { isInitialized -> isInitialized }
        .distinctUntilChanged()
        .catch { ex -> logger.error(ex.message ?: "CustomerIOReactNative -> initialization") }

    fun setLogLevel(logLevel: CioLogLevel) {
        (logger as ReactNativeConsoleLogger).logLevel = logLevel
    }

    internal fun setFCMTokenRegistered(): Boolean {
        return isFCMTokenRegistered.compareAndSet(false, true)
    }

    internal fun onSDKInitialized() {
        initializationStateFlow.value = true
        logger.info("Customer.io instance initialized successfully")
    }

    fun awaitSDKInitializationWithTimeout(
        timeoutDuration: Long = SDK_INITIALIZATION_TIMEOUT_DURATION_DEFAULT,
        block: () -> Unit,
    ) {
        logger.debug("awaiting initialization")
        runBlocking {
            val result = withTimeoutOrNull(timeMillis = timeoutDuration) {
                initializationFlow.collectLatest { block() }
            }
            if (result == null) logger.error("initialization wait cancelled")
            else logger.debug("initialization wait complete")
        }
    }
}
