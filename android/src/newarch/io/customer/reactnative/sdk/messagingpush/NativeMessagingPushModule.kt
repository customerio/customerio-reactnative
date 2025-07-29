package io.customer.reactnative.sdk.messagingpush

import com.facebook.react.bridge.Promise
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReadableMap
import io.customer.reactnative.sdk.NativeCustomerIOMessagingPushSpec
import io.customer.reactnative.sdk.util.unsupportedOnAndroid

/**
 * React Native module implementation for Customer.io Push Messaging Native SDK using
 * TurboModules with new architecture.
 */
class NativeMessagingPushModule(
    private val reactContext: ReactApplicationContext,
) : NativeCustomerIOMessagingPushSpec(reactContext) {

    override fun initialize() {
        super.initialize()
        reactContext.addActivityEventListener(NativeMessagingPushModuleImpl)
    }

    override fun invalidate() {
        reactContext.removeActivityEventListener(NativeMessagingPushModuleImpl)
        super.invalidate()
    }

    override fun onMessageReceived(
        message: ReadableMap?,
        handleNotificationTrigger: Boolean,
        promise: Promise?,
    ) {
        NativeMessagingPushModuleImpl.onMessageReceived(
            reactContext = reactContext,
            message = message,
            handleNotificationTrigger = handleNotificationTrigger,
            promise = promise,
        )
    }

    override fun trackNotificationResponseReceived(payload: ReadableMap?) {
        unsupportedOnAndroid(methodName = "trackNotificationResponseReceived")
    }

    override fun trackNotificationReceived(payload: ReadableMap?) {
        unsupportedOnAndroid(methodName = "trackNotificationReceived")
    }

    override fun getRegisteredDeviceToken(promise: Promise?) {
        NativeMessagingPushModuleImpl.getRegisteredDeviceToken(promise)
    }

    override fun showPromptForPushNotifications(options: ReadableMap?, promise: Promise?) {
        NativeMessagingPushModuleImpl.showPromptForPushNotifications(
            reactContext = reactContext,
            pushConfigurationOptions = options,
            promise = promise,
        )
    }

    override fun getPushPermissionStatus(promise: Promise?) {
        NativeMessagingPushModuleImpl.getPushPermissionStatus(
            reactContext = reactContext,
            promise = promise,
        )
    }
}
