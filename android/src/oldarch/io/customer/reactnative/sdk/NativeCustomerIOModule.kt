package io.customer.reactnative.sdk

import com.facebook.react.bridge.Promise
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactContextBaseJavaModule
import com.facebook.react.bridge.ReactMethod
import com.facebook.react.bridge.ReadableMap
import io.customer.reactnative.sdk.messaginginapp.RNCIOInAppMessaging
import io.customer.reactnative.sdk.messagingpush.RNCIOPushMessaging

/**
 * React Native module implementation for Customer.io Native SDK using using old architecture.
 */
class NativeCustomerIOModule(
    reactContext: ReactApplicationContext,
    private val pushMessagingModule: RNCIOPushMessaging,
    private val inAppMessagingModule: RNCIOInAppMessaging,
) : ReactContextBaseJavaModule(reactContext) {
    override fun getName(): String = NativeCustomerIOModuleImpl.NAME

    @ReactMethod
    fun initialize(
        configJson: ReadableMap,
        @Suppress("UNUSED_PARAMETER") sdkArgs: ReadableMap
    ) {
        NativeCustomerIOModuleImpl.initialize(
            reactContext = reactApplicationContext,
            sdkConfig = configJson,
            inAppMessagingModule = inAppMessagingModule,
            pushMessagingModule = pushMessagingModule
        )
    }

    @ReactMethod
    fun clearIdentify() {
        NativeCustomerIOModuleImpl.clearIdentify()
    }

    @ReactMethod
    fun identify(params: ReadableMap?) {
        NativeCustomerIOModuleImpl.identify(params = params)
    }

    @ReactMethod
    fun track(name: String, attributes: ReadableMap?) {
        NativeCustomerIOModuleImpl.track(name, attributes)
    }

    @ReactMethod
    fun setDeviceAttributes(attributes: ReadableMap?) {
        NativeCustomerIOModuleImpl.setDeviceAttributes(attributes)
    }

    @ReactMethod
    fun setProfileAttributes(attributes: ReadableMap?) {
        NativeCustomerIOModuleImpl.setProfileAttributes(attributes)
    }

    @ReactMethod
    fun screen(name: String, attributes: ReadableMap?) {
        NativeCustomerIOModuleImpl.screen(name, attributes)
    }

    @ReactMethod
    fun registerDeviceToken(token: String) {
        NativeCustomerIOModuleImpl.registerDeviceToken(token)
    }

    @ReactMethod
    fun deleteDeviceToken() {
        NativeCustomerIOModuleImpl.deleteDeviceToken()
    }

    @ReactMethod
    fun getPushPermissionStatus(promise: Promise) {
        pushMessagingModule.getPushPermissionStatus(promise)
    }

    @ReactMethod
    fun showPromptForPushNotifications(pushConfigurationOptions: ReadableMap?, promise: Promise) {
        pushMessagingModule.showPromptForPushNotifications(pushConfigurationOptions, promise)
    }
}
