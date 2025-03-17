package io.customer.reactnative.sdk.messagingpush

import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactContextBaseJavaModule
import com.facebook.react.bridge.Promise
import com.facebook.react.bridge.ReactMethod
import com.facebook.react.bridge.ReadableMap
import io.customer.sdk.CustomerIOBuilder
import io.customer.sdk.core.di.SDKComponent
import io.customer.sdk.core.util.Logger
import java.lang.IllegalStateException

/**
 * ReactNative module to hold push messages features in a single place to bridge with native code.
 */
class RNCIOPushMessaging(
    private val reactContext: ReactApplicationContext,
) : ReactContextBaseJavaModule(reactContext) {
    override fun getName(): String = "CioRctPushMessaging"

    private val logger: Logger = SDKComponent.logger

    /**
     * Adds push messaging module to native Android SDK based on the configuration provided by
     * customer app.
     *
     * @param builder instance of CustomerIOBuilder to add push messaging module.
     * @param config configuration provided by customer app for push messaging module.
     */
    internal fun addNativeModuleFromConfig(
        builder: CustomerIOBuilder,
        config: Map<String, Any>
    ) {
        // No-op
    }

    @ReactMethod
    fun getPushPermissionStatus(promise: Promise) {
        throw IllegalStateException("Push messaging is not enabled for CIO")
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
        throw IllegalStateException("Push messaging is not enabled for CIO")
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
        throw IllegalStateException("Push messaging is not enabled for CIO")
    }

    /**
     * Get the registered device token for the app.
     * @returns Promise with device token as a string, or error if no token is
     * registered or the method fails to fetch token.
     */
    @ReactMethod
    fun getRegisteredDeviceToken(promise: Promise) {
        throw IllegalStateException("Push messaging is not enabled for CIO")
    }
}
