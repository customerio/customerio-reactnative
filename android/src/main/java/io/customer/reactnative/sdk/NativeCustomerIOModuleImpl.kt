package io.customer.reactnative.sdk

import android.app.Application
import com.facebook.react.bridge.Promise
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
import io.customer.sdk.events.Metric
import io.customer.sdk.events.TrackMetric
import io.customer.sdk.events.serializedName

/**
 * Shared implementation logic for Customer.io Native SDK communication in React Native.
 * Contains actual business logic used by both old and new architecture [NativeCustomerIOModule] classes.
 * Handles SDK initialization, user identification, event tracking, and device management.
 */
internal object NativeCustomerIOModuleImpl {
    const val NAME = "NativeCustomerIO"

    private val logger: Logger
        get() = SDKComponent.logger

    // Returns CustomerIO instance if initialized, null otherwise, with configurable failure handling.
    private inline fun getSDKInstanceOrNull(
        onFailure: (exception: Throwable) -> Unit = {}
    ): CustomerIO? = runCatching {
        // If the SDK is not initialized, `CustomerIO.instance()` throws an exception
        CustomerIO.instance()
    }.onFailure(onFailure).getOrNull()

    // Returns CustomerIO instance if initialized, null otherwise, logging error on failure.
    private fun requireSDKInstance(): CustomerIO? = getSDKInstanceOrNull {
        logger.error("CustomerIO SDK is not initialized. Please call initialize() first.")
    }

    fun initialize(
        reactContext: ReactApplicationContext,
        sdkConfig: ReadableMap?,
        promise: Promise?
    ) {
        // Skip initialization if already initialized
        if (getSDKInstanceOrNull() != null) {
            logger.info("CustomerIO SDK is already initialized. Skipping initialization.")
            promise?.resolve(true)
            return
        }

        try {
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
            promise?.resolve(true)
        } catch (ex: Exception) {
            logger.error("Failed to initialize Customer.io instance from app, ${ex.message}")
            promise?.reject(ex)
        }
    }

    fun clearIdentify() {
        requireSDKInstance()?.clearIdentify()
    }

    fun identify(params: ReadableMap?) {
        val userId = params?.getString("userId")
        val traits = params?.getMap("traits")

        if (userId == null && traits == null) {
            logger.error("Either userId or traits must be provided for identify")
            return
        }

        userId?.let {
            requireSDKInstance()?.identify(userId, traits.toMap())
        } ?: run {
            requireSDKInstance()?.profileAttributes = traits.toMap()
        }
    }

    fun track(name: String?, properties: ReadableMap?) {
        val eventName = assertNotNull(name) ?: return

        requireSDKInstance()?.track(eventName, properties.toMap())
    }

    fun setDeviceAttributes(attributes: ReadableMap?) {
        requireSDKInstance()?.deviceAttributes = attributes.toMap()
    }

    fun setProfileAttributes(attributes: ReadableMap?) {
        requireSDKInstance()?.profileAttributes = attributes.toMap()
    }

    fun screen(title: String?, properties: ReadableMap?) {
        val screenTitle = assertNotNull(title) ?: return

        requireSDKInstance()?.screen(screenTitle, properties.toMap())
    }

    fun registerDeviceToken(token: String?) {
        val deviceToken = assertNotNull(token) ?: return

        requireSDKInstance()?.registerDeviceToken(deviceToken)
    }

    fun trackMetric(deliveryId: String?, deviceToken: String?, eventName: String?) {
        try {
            if (deliveryId == null || deviceToken == null || eventName == null) {
                throw IllegalArgumentException("Missing required parameters")
            }

            val event = Metric.values().find {
                it.serializedName.equals(eventName, true)
            } ?: throw IllegalArgumentException("Invalid metric event name")

            requireSDKInstance()?.trackMetric(
                event = TrackMetric.Push(
                    deliveryId = deliveryId,
                    deviceToken = deviceToken,
                    metric = event
                )
            )
        } catch (e: Exception) {
            logger.error("Error tracking push metric: ${e.message}")
        }
    }

    fun deleteDeviceToken() {
        requireSDKInstance()?.deleteDeviceToken()
    }
}
