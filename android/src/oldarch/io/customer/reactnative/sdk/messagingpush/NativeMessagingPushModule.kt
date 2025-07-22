package io.customer.reactnative.sdk.messagingpush

import com.facebook.react.bridge.Promise
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactContextBaseJavaModule
import com.facebook.react.bridge.ReactMethod
import com.facebook.react.bridge.ReadableMap

/**
 * React Native module implementation for Customer.io Push Messaging Native SDK using old architecture.
 */
class NativeMessagingPushModule(
    private val reactContext: ReactApplicationContext,
) : ReactContextBaseJavaModule(reactContext) {
    override fun getName(): String = NativeMessagingPushModuleImpl.NAME

    override fun initialize() {
        super.initialize()
        reactContext.addActivityEventListener(NativeMessagingPushModuleImpl)
    }

    override fun invalidate() {
        reactContext.removeActivityEventListener(NativeMessagingPushModuleImpl)
        super.invalidate()
    }

    @ReactMethod
    fun onMessageReceived(
        message: ReadableMap?,
        handleNotificationTrigger: Boolean,
        promise: Promise,
    ) {
        NativeMessagingPushModuleImpl.onMessageReceived(
            reactContext = reactContext,
            message = message,
            handleNotificationTrigger = handleNotificationTrigger,
            promise = promise,
        )
    }

    @ReactMethod
    fun getRegisteredDeviceToken(promise: Promise) {
        NativeMessagingPushModuleImpl.getRegisteredDeviceToken(promise)
    }

    @ReactMethod
    fun showPromptForPushNotifications(options: ReadableMap?, promise: Promise) {
        NativeMessagingPushModuleImpl.showPromptForPushNotifications(
            reactContext = reactContext,
            pushConfigurationOptions = options,
            promise = promise,
        )
    }

    @ReactMethod
    fun getPushPermissionStatus(promise: Promise) {
        NativeMessagingPushModuleImpl.getPushPermissionStatus(
            reactContext = reactContext,
            promise = promise,
        )
    }
}
