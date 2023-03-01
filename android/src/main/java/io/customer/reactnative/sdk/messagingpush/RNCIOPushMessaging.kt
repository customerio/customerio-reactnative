package io.customer.reactnative.sdk.messagingpush

import android.Manifest
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.content.ContextCompat
import com.facebook.react.bridge.*
import com.facebook.react.modules.core.PermissionAwareActivity
import com.facebook.react.modules.core.PermissionListener

/**
 * ReactNative module to hold push messages features in a single place to bridge with native code.
 */
class RNCIOPushMessaging(
    private val reactContext: ReactApplicationContext,
) : ReactContextBaseJavaModule(reactContext), PermissionListener {
    /**
     * Temporarily holds reference for notification request as the request is dependent on Android
     * lifecycle and cannot be completed instantly.
     */
    private var notificationRequestPromise: Promise? = null

    @ReactMethod
    fun getPushPermissionStatus(callback: Callback) {
        callback.invoke(checkPushPermissionStatus().toReactNativeResult)
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
