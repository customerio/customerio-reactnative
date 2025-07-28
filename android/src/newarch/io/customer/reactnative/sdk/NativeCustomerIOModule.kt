package io.customer.reactnative.sdk

import com.facebook.react.bridge.Promise
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReadableMap

/**
 * React Native module implementation for Customer.io Native SDK using using
 * Turbo Modules with new architecture.
 */
class NativeCustomerIOModule(
    private val reactContext: ReactApplicationContext,
) : NativeCustomerIOSpec(reactContext) {

    override fun initialize(config: ReadableMap?, args: ReadableMap?, promise: Promise?) {
        NativeCustomerIOModuleImpl.initialize(
            reactContext = reactContext,
            sdkConfig = config,
            promise = promise,
        )
    }

    override fun identify(params: ReadableMap?) {
        NativeCustomerIOModuleImpl.identify(params)
    }

    override fun clearIdentify() {
        NativeCustomerIOModuleImpl.clearIdentify()
    }

    override fun track(name: String?, properties: ReadableMap?) {
        NativeCustomerIOModuleImpl.track(name, properties)
    }

    override fun screen(title: String?, properties: ReadableMap?) {
        NativeCustomerIOModuleImpl.screen(title, properties)
    }

    override fun setProfileAttributes(attributes: ReadableMap?) {
        NativeCustomerIOModuleImpl.setProfileAttributes(attributes)
    }

    override fun setDeviceAttributes(attributes: ReadableMap?) {
        NativeCustomerIOModuleImpl.setDeviceAttributes(attributes)
    }

    override fun registerDeviceToken(token: String?) {
        NativeCustomerIOModuleImpl.registerDeviceToken(token)
    }

    override fun deleteDeviceToken() {
        NativeCustomerIOModuleImpl.deleteDeviceToken()
    }
}
