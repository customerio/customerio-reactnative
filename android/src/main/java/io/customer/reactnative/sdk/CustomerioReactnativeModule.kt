package io.customer.reactnative.sdk

import android.app.Application
import android.util.Log
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactContextBaseJavaModule
import com.facebook.react.bridge.ReactMethod
import com.facebook.react.bridge.ReadableMap
import io.customer.sdk.CustomerIO
import io.customer.sdk.data.model.Region
import io.customer.sdk.util.CioLogLevel

class CustomerioReactnativeModule(
    reactApplicationContext: ReactApplicationContext,
) : ReactContextBaseJavaModule(reactApplicationContext) {
    private val application: Application = reactApplicationContext.applicationContext as Application
    private lateinit var customerIO: CustomerIO

    override fun getName(): String {
        return "CustomerioReactnative"
    }

    fun logMessage(message: String) {
        Log.d("[CIO]", message)
    }

    private fun isInitialized(): Boolean {
        return ::customerIO.isInitialized
    }

    private fun isConfigurationsPending(): Boolean {
        val isPending = !isInitialized()
        if (isPending) {
            logMessage("Customer.io instance not initialized")
        }
        return isPending
    }

    @JvmOverloads
    @ReactMethod
    fun initialize(siteId: String, apiKey: String, region: String? = null) {
        if (isInitialized()) return

        customerIO = CustomerIO.Builder(
            siteId = siteId,
            apiKey = apiKey,
            region = region.toRegion() ?: Region.US,
            appContext = application,
        )
            .setLogLevel(CioLogLevel.DEBUG)
            .autoTrackDeviceAttributes(true)
            .build()

    }

    @ReactMethod
    fun config(attributes: ReadableMap?) {
        if (isInitialized()) {
            logMessage("Customer.io instance already initialized")
            return
        }
    }

    @ReactMethod
    fun clearIdentify() {
        if (isConfigurationsPending()) return

        customerIO.clearIdentify()
    }

    @ReactMethod
    fun identify(identifier: String, attributes: ReadableMap?) {
        if (isConfigurationsPending()) return

        customerIO.identify(identifier, attributes.toMap())
    }

    @ReactMethod
    fun track(name: String, attributes: ReadableMap?) {
        if (isConfigurationsPending()) return

        customerIO.track(name, attributes.toMap())
    }

    @ReactMethod
    fun setDeviceAttributes(attributes: ReadableMap?) {
        if (isConfigurationsPending()) return

        customerIO.deviceAttributes = attributes.toMap()
    }

    @ReactMethod
    fun setProfileAttributes(attributes: ReadableMap?) {
        if (isConfigurationsPending()) return

        customerIO.profileAttributes = attributes.toMap()
    }

    @ReactMethod
    fun screen(name: String, attributes: ReadableMap?) {
        if (isConfigurationsPending()) return

        customerIO.screen(name, attributes.toMap())
    }
}
