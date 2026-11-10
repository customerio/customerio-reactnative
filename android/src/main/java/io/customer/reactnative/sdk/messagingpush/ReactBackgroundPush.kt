package io.customer.reactnative.sdk.messagingpush

import android.content.ContentProvider
import android.content.ContentValues
import android.content.Context
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import androidx.concurrent.futures.CallbackToFutureAdapter
import androidx.work.Data
import androidx.work.ListenableWorker
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.OutOfQuotaPolicy
import androidx.work.WorkManager
import androidx.work.WorkerParameters
import androidx.work.workDataOf
import com.facebook.react.ReactApplication
import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.ReactContext
import com.facebook.react.jstasks.HeadlessJsTaskConfig
import com.facebook.react.jstasks.HeadlessJsTaskContext
import com.google.common.util.concurrent.ListenableFuture
import io.customer.messagingpush.data.communication.CustomerIOBackgroundPushCallback
import io.customer.messagingpush.data.model.CustomerIOBackgroundPushPayload
import io.customer.messagingpush.di.backgroundPushCallbackFallback
import io.customer.sdk.core.di.SDKComponent
import java.util.UUID

/**
 * Hands Customer.io silent pushes to the JavaScript handler set with `setBackgroundPushHandler`.
 *
 * Firebase's receive thread gets only a few seconds, so each push runs in a WorkManager job that
 * keeps the process alive while JavaScript handles it. A started service, React Native Firebase's
 * approach, can't start from the background for a normal-priority message.
 *
 * A push waits until JavaScript registers its handler, starting React Native if it isn't running,
 * and then runs as a Headless JS task, which keeps JavaScript timers running in the background. It
 * ends when JavaScript acknowledges it or after [TIMEOUT_MS]. A push starts a job only once
 * JavaScript has set a handler, so apps that don't use silent push see no change.
 */
internal object ReactBackgroundPush : CustomerIOBackgroundPushCallback {
    /** Keep in sync with `BACKGROUND_PUSH_TASK` in customerio-push.ts. */
    private const val TASK_KEY = "CustomerIOBackgroundPush"

    /** Counted from when the job starts, so it includes starting React Native, as on iOS. */
    private const val TIMEOUT_MS = 25_000L

    private const val PREFERENCES = "io.customer.reactnative.background-push"
    private const val KEY_HANDLER_SET = "handlerSet"
    private const val KEY_DELIVERY_ID = "deliveryId"
    private const val KEY_DELIVERY_TOKEN = "deliveryToken"
    private const val DATA_PREFIX = "data."

    private class Pending(val push: Data, val finish: () -> Unit) {
        var task: Pair<ReactContext, Int>? = null
    }

    private val main = Handler(Looper.getMainLooper())

    // The React instance whose JavaScript set the handler. Written on the main thread.
    @Volatile
    private var handlerContext: ReactContext? = null

    // Main thread only.
    private val pending = mutableMapOf<String, Pending>()

    override fun onBackgroundPushReceived(context: Context, payload: CustomerIOBackgroundPushPayload) {
        if (handlerContext == null && !preferences(context).getBoolean(KEY_HANDLER_SET, false)) return

        val request = OneTimeWorkRequestBuilder<ReactBackgroundPushWorker>()
            .setInputData(
                workDataOf(
                    KEY_DELIVERY_ID to payload.deliveryId,
                    KEY_DELIVERY_TOKEN to payload.deliveryToken,
                    *payload.data.map { (key, value) -> DATA_PREFIX + key to value }.toTypedArray(),
                )
            )
            .apply {
                // Before Android 12, expedited work needs a foreground notification, and a silent
                // push must never show anything.
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    setExpedited(OutOfQuotaPolicy.RUN_AS_NON_EXPEDITED_WORK_REQUEST)
                }
            }
            .build()
        WorkManager.getInstance(context).enqueue(request)
    }

    /** Called by the job on the main thread. */
    fun run(context: Context, id: String, push: Data, finish: () -> Unit) {
        pending[id] = Pending(push, finish)
        main.postDelayed({
            val entry = pending[id] ?: return@postDelayed
            // JavaScript never registered, so this version of the app no longer sets a handler.
            if (entry.task == null) forget(context)
            complete(id)
        }, TIMEOUT_MS)
        val handler = handlerContext
        if (handler != null) {
            startTask(handler, id)
        } else {
            (context.applicationContext as? ReactApplication)?.reactHost?.start()
        }
    }

    fun stop(id: String) {
        main.post { complete(id) }
    }

    fun register(context: ReactContext) {
        preferences(context).edit().putBoolean(KEY_HANDLER_SET, true).apply()
        main.post {
            handlerContext = context
            pending.keys.toList().forEach { startTask(context, it) }
        }
    }

    /** JavaScript removed its handler. */
    fun unregister(context: ReactContext) {
        forget(context)
        main.post {
            if (handlerContext === context) handlerContext = null
        }
    }

    /** The React instance is going away, as on a reload; pushes it didn't finish go to the next one. */
    fun release(context: ReactContext) {
        main.post {
            if (handlerContext === context) handlerContext = null
            pending.forEach { (id, entry) ->
                if (entry.task?.first === context) {
                    entry.task = null
                    handlerContext?.let { startTask(it, id) }
                }
            }
        }
    }

    fun acknowledge(id: String) {
        main.post { complete(id) }
    }

    private fun startTask(context: ReactContext, id: String) {
        val entry = pending[id] ?: return
        if (entry.task != null) return
        val push = entry.push
        val data = Arguments.createMap()
        push.keyValueMap.forEach { (key, value) ->
            if (key.startsWith(DATA_PREFIX)) data.putString(key.removePrefix(DATA_PREFIX), value as String)
        }
        val event = Arguments.createMap().apply {
            putString("id", id)
            putMap(
                "push",
                Arguments.createMap().apply {
                    putString("deliveryId", push.getString(KEY_DELIVERY_ID))
                    putString("deliveryToken", push.getString(KEY_DELIVERY_TOKEN))
                    putMap("data", data)
                }
            )
        }
        // No task timeout: this object ends the task, since React Native's bridgeless runtime
        // never reports a finished task.
        val taskId = HeadlessJsTaskContext.getInstance(context)
            .startTask(HeadlessJsTaskConfig(TASK_KEY, event, 0, true))
        entry.task = context to taskId
    }

    private fun complete(id: String) {
        val entry = pending.remove(id) ?: return
        entry.task?.let { (context, taskId) ->
            val tasks = HeadlessJsTaskContext.getInstance(context)
            if (tasks.isTaskRunning(taskId)) tasks.finishTask(taskId)
        }
        entry.finish()
    }

    private fun forget(context: Context) {
        preferences(context).edit().remove(KEY_HANDLER_SET).apply()
    }

    private fun preferences(context: Context) =
        context.applicationContext.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE)
}

internal class ReactBackgroundPushWorker(
    context: Context,
    params: WorkerParameters,
) : ListenableWorker(context, params) {
    // WorkManager can stop a job and run it again with the same work ID, so each run has its own.
    private val runId = UUID.randomUUID().toString()

    override fun startWork(): ListenableFuture<Result> =
        CallbackToFutureAdapter.getFuture { completer ->
            ReactBackgroundPush.run(applicationContext, runId, inputData) {
                completer.set(Result.success())
            }
            "Customer.io silent push"
        }

    override fun onStopped() {
        ReactBackgroundPush.stop(runId)
    }
}

/**
 * Sets the silent push callback when the process starts, before JavaScript runs, since Firebase
 * can start a killed app's process just to deliver a push. A callback in the app's own push config
 * takes precedence.
 */
internal class ReactBackgroundPushInitProvider : ContentProvider() {
    override fun onCreate(): Boolean {
        SDKComponent.backgroundPushCallbackFallback.callback = ReactBackgroundPush
        return true
    }

    override fun query(
        uri: Uri,
        projection: Array<out String>?,
        selection: String?,
        selectionArgs: Array<out String>?,
        sortOrder: String?,
    ) = null

    override fun getType(uri: Uri): String? = null

    override fun insert(uri: Uri, values: ContentValues?): Uri? = null

    override fun delete(uri: Uri, selection: String?, selectionArgs: Array<out String>?) = 0

    override fun update(
        uri: Uri,
        values: ContentValues?,
        selection: String?,
        selectionArgs: Array<out String>?,
    ) = 0
}
