package io.customer.reactnative.sdk

import androidx.annotation.WorkerThread
import com.google.android.gms.tasks.Task
import com.google.android.gms.tasks.TaskCompletionSource
import com.google.android.gms.tasks.Tasks
import io.customer.reactnative.sdk.util.ReactNativeConsoleLogger
import io.customer.sdk.util.CioLogLevel
import io.customer.sdk.util.Logger
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.catch
import kotlinx.coroutines.flow.filter
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicBoolean

/**
 * Static property holder for ReactNative package to overcome SDK
 * initialization challenges
 */
object CustomerIOReactNativeInstance {
    internal val logger: Logger = ReactNativeConsoleLogger(CioLogLevel.ERROR)
    internal var cachedFCMToken: String? = null

    private val isFCMTokenRegistered = AtomicBoolean(false)
    private val initializationStateFlow = MutableStateFlow(value = false)
    private val initializationFlow = initializationStateFlow.asStateFlow()
        .filter { isInitialized -> isInitialized }
        .catch { ex -> logger.error(ex.message ?: "CustomerIOReactNative -> initialization") }
    private val initializationTaskSource = TaskCompletionSource<Boolean>()
    private val initializationTask: Task<Boolean?> = initializationTaskSource.task

    fun setLogLevel(logLevel: CioLogLevel) {
        (logger as ReactNativeConsoleLogger).logLevel = logLevel
    }

    internal fun setFCMTokenRegistered(): Boolean {
        return isFCMTokenRegistered.compareAndSet(false, true)
    }

    internal fun onSDKInitialized() {
        initializationTaskSource.trySetResult(true)
        initializationStateFlow.value = true
        logger.info("Customer.io instance initialized successfully")
    }

    fun awaitSDKInitializationAsync(block: () -> Unit) {
        awaitSDKInitializationInternal(timeoutDuration = null, block = block)
    }

    @WorkerThread
    fun awaitSDKInitializationWithTimeout(timeoutDuration: Long, block: () -> Unit) {
        awaitSDKInitializationInternal(timeoutDuration = timeoutDuration, block = block)
    }

    private fun awaitSDKInitializationInternal(timeoutDuration: Long?, block: () -> Unit) {
        val onComplete = { result: Boolean? ->
            block()
            if (result == null) logger.error("initialization wait cancelled")
            else logger.debug("initialization wait complete")
        }
        if (timeoutDuration == null) {
            logger.debug("awaiting initialization async")
            initializationTask.addOnCompleteListener { task -> onComplete(task.result) }
        } else {
            logger.debug("awaiting initialization with timeout $timeoutDuration")
            try {
                onComplete(Tasks.await(initializationTask, timeoutDuration, TimeUnit.SECONDS))
            } catch (ex: Exception) {
                logger.error("initialization wait cancelled ${ex.message}")
            }
        }
    }
}
