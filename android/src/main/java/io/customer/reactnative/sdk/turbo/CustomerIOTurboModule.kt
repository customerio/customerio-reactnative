package io.customer.reactnative.sdk.turbo

import android.app.Application
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReadableMap
import com.facebook.react.turbomodule.core.CallInvokerHolderImpl
import com.facebook.react.turbomodule.core.interfaces.TurboModule
import io.customer.datapipelines.config.ScreenView
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

/**
 * TurboModule implementation for CustomerIO core functionality
 */
class CustomerIOTurboModule(
    private val reactContext: ReactApplicationContext,
    private val pushMessagingModule: RNCIOPushMessaging,
    private val inAppMessagingModule: RNCIOInAppMessaging,
) : TurboModule {

    override fun getName(): String = "CustomerIOModule"

    private val logger: Logger = SDKComponent.logger
    private fun customerIO(): CustomerIO? = runCatching {
        // If the SDK is not initialized, `CustomerIO.instance()` throws an exception
        CustomerIO.instance()
    }.onFailure {
        logger.error("Customer.io instance not initialized")
    }.getOrNull()

    /**
     * Initialize the CustomerIO SDK
     */
    fun initialize(config: ReadableMap, packageInfo: ReadableMap) {
        try {
            val packageConfig = config.toMap()
            val cdpApiKey = packageConfig.getTypedValue<String>(
                Keys.Config.CDP_API_KEY
            ) ?: throw IllegalArgumentException("CDP API Key is required to initialize Customer.io")

            val logLevelRawValue = packageConfig.getTypedValue<String>(Keys.Config.LOG_LEVEL)
            val regionRawValue = packageConfig.getTypedValue<String>(Keys.Config.REGION)
            val region = regionRawValue.let { Region.getRegion(it) }
            val screenViewRawValue = packageConfig.getTypedValue<String>(Keys.Config.SCREEN_VIEW_USE)

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

    /**
     * Clear the current user identification
     */
    fun clearIdentify() {
        customerIO()?.clearIdentify()
    }

    /**
     * Identify a user
     */
    fun identify(userId: String?, traits: ReadableMap?) {
        if (userId == null && traits == null) {
            logger.error("Please provide either an ID or traits to identify.")
            return
        }
        userId?.let {
            customerIO()?.identify(userId, traits.toMap())
        } ?: run {
            customerIO()?.profileAttributes = traits.toMap()
        }
    }

    /**
     * Track an event
     */
    fun track(name: String, properties: ReadableMap?) {
        customerIO()?.track(name, properties.toMap())
    }

    /**
     * Set device attributes
     */
    fun setDeviceAttributes(attributes: ReadableMap?) {
        customerIO()?.deviceAttributes = attributes.toMap()
    }

    /**
     * Set profile attributes
     */
    fun setProfileAttributes(attributes: ReadableMap?) {
        customerIO()?.profileAttributes = attributes.toMap()
    }

    /**
     * Track a screen view
     */
    fun screen(title: String, properties: ReadableMap?) {
        customerIO()?.screen(title, properties.toMap())
    }

    /**
     * Register a device token for push notifications
     */
    fun registerDeviceToken(token: String) {
        customerIO()?.registerDeviceToken(token)
    }

    /**
     * Delete the registered device token
     */
    fun deleteDeviceToken() {
        customerIO()?.deleteDeviceToken()
    }
}