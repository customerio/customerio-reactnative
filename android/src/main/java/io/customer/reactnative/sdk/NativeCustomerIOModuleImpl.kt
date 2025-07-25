package io.customer.reactnative.sdk

import android.app.Application
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReadableMap
import io.customer.datapipelines.config.ScreenView
import io.customer.reactnative.sdk.constant.Keys
import io.customer.reactnative.sdk.extension.getTypedValue
import io.customer.reactnative.sdk.extension.toMap
import io.customer.reactnative.sdk.messaginginapp.NativeMessagingInAppModuleImpl
import io.customer.reactnative.sdk.messagingpush.NativeMessagingPushModuleImpl
import io.customer.reactnative.sdk.util.assertNotNull
import io.customer.sdk.CustomerIO
import io.customer.sdk.CustomerIOBuilder
import io.customer.sdk.core.di.SDKComponent
import io.customer.sdk.core.util.CioLogLevel
import io.customer.sdk.core.util.Logger
import io.customer.sdk.data.model.Region

/**
 * Shared implementation logic for Customer.io Native SDK communication in React Native.
 * Contains actual business logic used by both old and new architecture [NativeCustomerIOModule] classes.
 * Handles SDK initialization, user identification, event tracking, and device management.
 */
internal object NativeCustomerIOModuleImpl {
    const val NAME = "NativeCustomerIO"

    private val logger: Logger
        get() = SDKComponent.logger

    private fun customerIO(): CustomerIO? = runCatching {
        // If the SDK is not initialized, `CustomerIO.instance()` throws an exception
        CustomerIO.instance()
    }.onFailure {
        logger.error("Customer.io instance not initialized")
    }.getOrNull()

    fun initialize(
        reactContext: ReactApplicationContext,
        sdkConfig: ReadableMap?,
    ) {
        try {
            // Skip initialization if SDK instance already exists
            val isSDKInitialized = runCatching { CustomerIO.instance() }.isSuccess
            if (isSDKInitialized) {
                logger.error("Customer.io SDK is already initialized. Skipping initialization.")
                return
            }

            val packageConfig = sdkConfig.toMap()
            val cdpApiKey = packageConfig.getTypedValue<String>(
                Keys.Config.CDP_API_KEY
            ) ?: throw IllegalArgumentException("CDP API Key is required to initialize Customer.io")

            val logLevelRawValue = packageConfig.getTypedValue<String>(Keys.Config.LOG_LEVEL)
            val regionRawValue = packageConfig.getTypedValue<String>(Keys.Config.REGION)
            val region = regionRawValue.let { Region.getRegion(it) }
            val screenViewRawValue =
                packageConfig.getTypedValue<String>(Keys.Config.SCREEN_VIEW_USE)

            CustomerIOBuilder(
                applicationContext = reactContext.applicationContext as Application,
                cdpApiKey = cdpApiKey
            ).apply {
                logLevelRawValue?.let { logLevel(CioLogLevel.getLogLevel(it)) }
                regionRawValue?.let { region(region) }
                screenViewRawValue?.let { screenViewUse(ScreenView.getScreenView(it)) }

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
                    NativeMessagingPushModuleImpl.addNativeModuleFromConfig(
                        builder = this,
                        config = pushConfig ?: emptyMap()
                    )
                }
                // Configure in-app messaging module based on config provided by customer app
                packageConfig.getTypedValue<Map<String, Any>>(key = "inApp")?.let { inAppConfig ->
                    NativeMessagingInAppModuleImpl.addNativeModuleFromConfig(
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

    fun clearIdentify() {
        customerIO()?.clearIdentify()
    }

    fun identify(params: ReadableMap?) {
        val userId = params?.getString("userId")
        val traits = params?.getMap("traits")

        if (userId == null && traits == null) {
            logger.error("Either userId or traits must be provided for identify")
            return
        }

        userId?.let {
            customerIO()?.identify(userId, traits.toMap())
        } ?: run {
            customerIO()?.profileAttributes = traits.toMap()
        }
    }

    fun track(name: String?, properties: ReadableMap?) {
        val eventName = assertNotNull(name) ?: return

        customerIO()?.track(eventName, properties.toMap())
    }

    fun setDeviceAttributes(attributes: ReadableMap?) {
        customerIO()?.deviceAttributes = attributes.toMap()
    }

    fun setProfileAttributes(attributes: ReadableMap?) {
        customerIO()?.profileAttributes = attributes.toMap()
    }

    fun screen(title: String?, properties: ReadableMap?) {
        val screenTitle = assertNotNull(title) ?: return

        customerIO()?.screen(screenTitle, properties.toMap())
    }

    fun registerDeviceToken(token: String?) {
        val deviceToken = assertNotNull(token) ?: return

        customerIO()?.registerDeviceToken(deviceToken)
    }

    fun deleteDeviceToken() {
        customerIO()?.deleteDeviceToken()
    }
}
