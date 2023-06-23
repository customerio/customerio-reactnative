package io.customer.reactnative.sdk.messagingpush

import android.Manifest
import android.app.Activity
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.content.ContextCompat
import com.facebook.react.bridge.*
import com.facebook.react.modules.core.PermissionAwareActivity
import com.facebook.react.modules.core.PermissionListener
import io.customer.messagingpush.CustomerIOFirebaseMessagingService
import io.customer.messagingpush.di.pushMessaging
import io.customer.messagingpush.di.pushTrackingUtil
import io.customer.reactnative.sdk.extension.takeIfNotBlank
import io.customer.reactnative.sdk.extension.toFCMRemoteMessage
import io.customer.sdk.CustomerIO
import io.customer.sdk.CustomerIOShared
import io.customer.sdk.util.Logger
import java.util.*

/**
 * ReactNative module to hold push messages features in a single place to bridge with native code.
 */
class RNCIOPushMessaging(
    private val reactContext: ReactApplicationContext,
) : ReactContextBaseJavaModule(reactContext), PermissionListener, ActivityEventListener {
    private val logger: Logger
        get() = CustomerIOShared.instance().diStaticGraph.logger

    /**
     * Temporarily holds reference for notification request as the request is dependent on Android
     * lifecycle and cannot be completed instantly.
     */
    private var notificationRequestPromise: Promise? = null

    init {
        reactContext.addActivityEventListener(this)
    }

    @ReactMethod
    fun getPushPermissionStatus(promise: Promise) {
        promise.resolve(checkPushPermissionStatus().toReactNativeResult)
    }

    /**
     * To request push notification permissions using native apis. Push notifications doesn't
     * require permissions for Android versions older than 13, so the results are returned instantly.
     * For newer versions, the permission is requested and the promise is resolved after the request
     * has been completed.
     *
     * @param pushConfigurationOptions configurations options for push notifications, required for
     * iOS only, unused on Android.
     * @param promise to resolve and return the results.
     */
    @ReactMethod
    fun showPromptForPushNotifications(pushConfigurationOptions: ReadableMap?, promise: Promise) {
        // Skip requesting permissions when already granted
        if (checkPushPermissionStatus() == PermissionStatus.Granted) {
            promise.resolve(PermissionStatus.Granted.toReactNativeResult)
            return
        }

        try {
            val activity = currentActivity
            val permissionAwareActivity = activity as? PermissionAwareActivity
            if (permissionAwareActivity == null) {
                promise.reject(
                    "E_ACTIVITY_DOES_NOT_EXIST",
                    "Permission cannot be requested because activity doesn't exist. Please make sure to request permission from UI components only"
                )
                return
            }

            notificationRequestPromise = promise
            permissionAwareActivity.requestPermissions(
                arrayOf(POST_NOTIFICATIONS_PERMISSION_NAME),
                POST_NOTIFICATIONS_PERMISSION_REQUEST,
                this,
            )
        } catch (ex: Throwable) {
            promise.reject(ex)
            notificationRequestPromise = null
        }
    }

    /**
     * Handles push notification received. This is helpful in processing push notifications
     * received outside the CIO SDK.
     *
     * @param message push payload received from FCM.
     * @param handleNotificationTrigger indicating if the local notification should be triggered.
     */
    @ReactMethod
    fun handleMessage(message: ReadableMap?, handleNotificationTrigger: Boolean, promise: Promise) {
        try {
            if (message == null) {
                promise.reject(IllegalArgumentException("Remote message cannot be null"))
                return
            }

            // Generate destination string, see docs on receiver method for more details
            val destination =
                message.getString("to")?.takeIfNotBlank() ?: UUID.randomUUID().toString()
            val isNotificationHandled = CustomerIOFirebaseMessagingService.onMessageReceived(
                context = reactContext,
                remoteMessage = message.toFCMRemoteMessage(destination = destination),
                handleNotificationTrigger = handleNotificationTrigger,
            )
            promise.resolve(isNotificationHandled)
        } catch (ex: Throwable) {
            logger.error("Unable to handle push notification, reason: ${ex.message}")
            promise.reject(ex)
        }
    }

    /**
     * Checks current permission of push notification permission
     */
    private fun checkPushPermissionStatus(): PermissionStatus =
        // Skip requesting permissions for older versions where not required
        if (Build.VERSION.SDK_INT < BUILD_VERSION_CODE_TIRAMISU || ContextCompat.checkSelfPermission(
                reactContext, POST_NOTIFICATIONS_PERMISSION_NAME,
            ) == PackageManager.PERMISSION_GRANTED
        ) PermissionStatus.Granted
        else PermissionStatus.Denied

    /**
     * Resolves and clears promise with the provided permission status
     */
    private fun resolvePermissionPromise(status: PermissionStatus) {
        notificationRequestPromise?.resolve(status.toReactNativeResult)
        notificationRequestPromise = null
    }

    override fun onRequestPermissionsResult(
        requestCode: Int, permissions: Array<String>, grantResults: IntArray,
    ): Boolean = when (requestCode) {
        POST_NOTIFICATIONS_PERMISSION_REQUEST -> {
            // If request is cancelled, the result arrays are empty.
            if (grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                resolvePermissionPromise(PermissionStatus.Granted)
            } else {
                resolvePermissionPromise(PermissionStatus.Denied)
            }
            true // as this permission listener can be removed now
        }

        else -> false // desired permission not yet granted, so we will keep the listener
    }

    override fun onActivityResult(
        activity: Activity?,
        requestCode: Int,
        resultCode: Int,
        intent: Intent?,
    ) {
        // Nothing required here
    }

    /**
     * If the app is in background and simple push is received, then FCM notification doesn't
     * start new intent apparently because of `singleTask` launchMode being used by React Native
     * apps. Due to this, onCreate activity callback is not triggered and the push notification
     * is not tracked.
     *
     * But onNewIntent is called when the app is launched from background and the intent is
     * received, which helps us tracking the simple push notifications opened metrics.
     */
    override fun onNewIntent(intent: Intent?) {
        val intentArguments = intent?.extras ?: return
        kotlin.runCatching {
            val sdkInstance = CustomerIO.instance()
            val pushMessagingModuleConfig = sdkInstance.pushMessaging().moduleConfig

            if (pushMessagingModuleConfig.autoTrackPushEvents) {
                sdkInstance.diGraph.pushTrackingUtil
                    .parseLaunchedActivityForTracking(intentArguments)
            }
        }.onFailure { ex ->
            logger.error("Unable to parse push notification intent, reason: ${ex.message}")
        }
    }

    override fun getName(): String = "CustomerioPushMessaging"

    /**
     * Maps native class to react native supported type so the result can be passed on to JS/TS classes.
     */
    private val PermissionStatus.toReactNativeResult: Any
        get() = this.name

    companion object {
        /**
         * Copying value os [Manifest.permission.POST_NOTIFICATIONS] as constant so we don't have to
         * force newer compile sdk versions
         */
        private const val POST_NOTIFICATIONS_PERMISSION_NAME =
            "android.permission.POST_NOTIFICATIONS"
        private const val BUILD_VERSION_CODE_TIRAMISU = 33
        private const val POST_NOTIFICATIONS_PERMISSION_REQUEST = 24676
    }
}
