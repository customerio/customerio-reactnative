package io.customer.reactnative.sdk

import android.app.Application
import com.facebook.react.bridge.Promise
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactContextBaseJavaModule
import com.facebook.react.bridge.ReactMethod
import com.facebook.react.bridge.ReadableMap
import io.customer.reactnative.sdk.constant.Keys
import io.customer.reactnative.sdk.extension.getTypedValue
import io.customer.reactnative.sdk.extension.toMap
import io.customer.reactnative.sdk.messaginginapp.RNCIOInAppMessaging
import io.customer.reactnative.sdk.messagingpush.RNCIOPushMessaging
import io.customer.sdk.CustomerIO
import io.customer.sdk.CustomerIOBuilder
import io.customer.sdk.core.di.SDKComponent
import io.customer.sdk.core.util.CioLogLevel
import io.customer.sdk.core.util.Logger
import io.customer.sdk.data.model.Region

class CustomerIOReactNativeModule(
    reactContext: ReactApplicationContext,
    private val pushMessagingModule: RNCIOPushMessaging,
    private val inAppMessagingModule: RNCIOInAppMessaging,
) : ReactContextBaseJavaModule(reactContext) {
    override fun getName(): String = "NativeCustomerIO"

    private val logger: Logger = SDKComponent.logger
    private fun customerIO(): CustomerIO? = runCatching {
        // If the SDK is not initialized, `CustomerIO.instance()` throws an exception
        CustomerIO.instance()
    }.onFailure {
        logger.error("Customer.io instance not initialized")
    }.getOrNull()

    @ReactMethod
    fun initialize(configJson: ReadableMap, sdkArgs: ReadableMap) {
        try {
            val packageConfig = configJson.toMap()
            val cdpApiKey = packageConfig.getTypedValue<String>(
                Keys.Config.CDP_API_KEY
            ) ?: throw IllegalArgumentException("CDP API Key is required to initialize Customer.io")

            val logLevelRawValue = packageConfig.getTypedValue<String>(Keys.Config.LOG_LEVEL)
            val regionRawValue = packageConfig.getTypedValue<String>(Keys.Config.REGION)
            val region = regionRawValue.let { Region.getRegion(it) }

            CustomerIOBuilder(
                applicationContext = reactApplicationContext.applicationContext as Application,
                cdpApiKey = cdpApiKey
            ).apply {
                logLevelRawValue?.let { logLevel(CioLogLevel.getLogLevel(it)) }
                regionRawValue?.let { region(region) }

                packageConfig.getTypedValue<Boolean>(Keys.Config.AUTO_TRACK_DEVICE_ATTRIBUTES)
                    ?.let { autoTrackDeviceAttributes(it) }
                packageConfig.getTypedValue<String>(Keys.Config.MIGRATION_SITE_ID)
                    ?.let { migrationSiteId(it) }
                packageConfig.getTypedValue<Int>(Keys.Config.FLUSH_AT)
                    ?.let { flushAt(it) }
                packageConfig.getTypedValue<Int>(Keys.Config.FLUSH_INTERVAL)
                    ?.let { flushInterval(it) }
                packageConfig.getTypedValue<Boolean>(Keys.Config.TRACK_APP_LIFECYCLE_EVENTS)
                    ?.let { trackApplicationLifecycleEvents(it) }

                // Configure push messaging module based on config provided by customer app
                packageConfig.getTypedValue<Map<String, Any>>(key = "push").let { pushConfig ->
                    pushMessagingModule.addNativeModuleFromConfig(
                        builder = this,
                        config = pushConfig ?: emptyMap()
                    )
                }
                // Configure in-app messaging module based on config provided by customer app
                packageConfig.getTypedValue<Map<String, Any>>(key = "inApp")?.let { inAppConfig ->
                    inAppMessagingModule.addNativeModuleFromConfig(
                        builder = this,
                        config = inAppConfig,
                        region = region
                    )
                }
            }.build()

            logger.info("Customer.io instance initialized successfully from app")
        } catch (ex: Exception) {
            logger.error("Failed to initialize Customer.io instance from app, ${ex.message}")
        }
    }

    @ReactMethod
    fun clearIdentify() {
        customerIO()?.clearIdentify()
    }

    @ReactMethod
    fun identify(identifier: String?, attributes: ReadableMap?) {
        if (identifier == null && attributes == null) {
            logger.error("Please provide either an ID or traits to identify.")
            return
        }
        identifier?.let {
            customerIO()?.identify(identifier, attributes.toMap())
        } ?: run {
            customerIO()?.profileAttributes = attributes.toMap()
        }
    }

    @ReactMethod
    fun track(name: String, attributes: ReadableMap?) {
        customerIO()?.track(name, attributes.toMap())
    }

    @ReactMethod
    fun setDeviceAttributes(attributes: ReadableMap?) {
        customerIO()?.deviceAttributes = attributes.toMap()
    }

    @ReactMethod
    fun setProfileAttributes(attributes: ReadableMap?) {
        customerIO()?.profileAttributes = attributes.toMap()
    }

    @ReactMethod
    fun screen(name: String, attributes: ReadableMap?) {
        customerIO()?.screen(name, attributes.toMap())
    }

    @ReactMethod
    fun registerDeviceToken(token: String) {
        customerIO()?.registerDeviceToken(token)
    }

    @ReactMethod
    fun deleteDeviceToken() {
        customerIO()?.deleteDeviceToken()
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
