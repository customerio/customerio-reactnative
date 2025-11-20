package io.customer.reactnative.sdk

import com.facebook.react.bridge.Promise
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactContextBaseJavaModule
import com.facebook.react.bridge.ReactMethod
import com.facebook.react.bridge.ReadableMap

/**
 * React Native module implementation for Customer.io Native SDK using using old architecture.
 */
class NativeCustomerIOModule(
    reactContext: ReactApplicationContext,
) : ReactContextBaseJavaModule(reactContext) {
    override fun getName(): String = NativeCustomerIOModuleImpl.NAME

    @ReactMethod
    fun initialize(
        configJson: ReadableMap,
        @Suppress("UNUSED_PARAMETER") sdkArgs: ReadableMap?,
        promise: Promise?,
    ) {
        NativeCustomerIOModuleImpl.initialize(
            reactContext = reactApplicationContext,
            sdkConfig = configJson,
            promise = promise,
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
    fun trackMetric(deliveryID: String, deviceToken: String, event: String) {
        NativeCustomerIOModuleImpl.trackMetric(deliveryID, deviceToken, event)
    }

    @ReactMethod
    fun deleteDeviceToken() {
        NativeCustomerIOModuleImpl.deleteDeviceToken()
    }
}
