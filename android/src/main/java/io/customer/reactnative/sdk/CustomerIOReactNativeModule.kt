package io.customer.reactnative.sdk

import android.app.Application
import com.facebook.react.bridge.Promise
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactContextBaseJavaModule
import com.facebook.react.bridge.ReactMethod
import com.facebook.react.bridge.ReadableMap
import io.customer.messagingpush.MessagingPushModuleConfig
import io.customer.messagingpush.ModuleMessagingPushFCM
import io.customer.messagingpush.config.PushClickBehavior
import io.customer.reactnative.sdk.constant.Keys
import io.customer.reactnative.sdk.extension.getProperty
import io.customer.reactnative.sdk.extension.takeIfNotBlank
import io.customer.reactnative.sdk.extension.toMap
import io.customer.reactnative.sdk.logging.CustomerIOReactNativeLoggingWrapper
import io.customer.reactnative.sdk.messagingpush.RNCIOPushMessaging
import io.customer.sdk.CustomerIO
import io.customer.sdk.CustomerIOBuilder
import io.customer.sdk.core.util.CioLogLevel
import io.customer.sdk.core.util.Logger
import io.customer.sdk.data.model.Region
import io.customer.messaginginapp.MessagingInAppModuleConfig
import io.customer.messaginginapp.ModuleMessagingInApp
import io.customer.messagingpush.ModuleMessagingPushFCM


class NativeCustomerIOModule(
    private val reactContext: ReactApplicationContext,
    private val pushMessagingModule: RNCIOPushMessaging,
    private val inAppMessagingModule: RNCIOInAppMessaging,
) : ReactContextBaseJavaModule(reactContext) {
    private lateinit var logger: Logger

    // If the SDK is not initialized, `CustomerIO.instance()` throws an exception
    private val customerIOInstance: CustomerIO?
        get() = kotlin.runCatching { CustomerIO.instance() }.getOrNull()

    override fun getName(): String {
        return MODULE_NAME
    }

    private fun customerIO(): CustomerIO? {
        val sdkInstance = customerIOInstance
        if (sdkInstance == null) {
            logger.error("Customer.io instance not initialized")
        }
        return sdkInstance
    }

    @ReactMethod
    fun initialize(
        configJson: ReadableMap,
        logLevel: String) {

        logger = CustomerIOReactNativeLoggingWrapper.getInstance(reactContext, CioLogLevel.getLogLevel(logLevel))
        val packageConfig = configJson.toMap()
        val cdpApiKey = packageConfig[Keys.Config.CDP_API_KEY]
        try {
            val builder = CustomerIOBuilder(
                applicationContext = reactApplicationContext.applicationContext as Application,
                cdpApiKey = cdpApiKey.toString()
            ).apply {

                (packageConfig[Keys.Config.AUTO_TRACK_DEVICE_ATTRIBUTES] as? Boolean)
                ?.let { autoTrackDeviceAttributes(it) }
                (packageConfig[Keys.Config.MIGRATION_SITE_ID] as? String)
                ?.let { migrationSiteId(it) }
                (packageConfig[Keys.Config.REGION] as? String)
                ?.let { region(Region.getRegion(it)) }
                logLevel(CioLogLevel.getLogLevel(logLevel))
                (packageConfig[Keys.Config.FLUSH_AT] as? Int)
                ?.let { flushAt(it) }
                (packageConfig[Keys.Config.FLUSH_INTERVAL] as? Int)
                ?.let { flushInterval(it) }
                (packageConfig[Keys.Config.TRACK_APP_LIFECYCLE_EVENTS] as? Boolean)
                ?.let { trackApplicationLifecycleEvents(it) }

                addCustomerIOModule(module = configureModuleMessagingPushFCM(packageConfig))
            }.build()
            logger.info("Customer.io instance initialized successfully from app")

        }
        catch (ex: Exception) {
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
        }?: run {
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

    private fun configureModuleMessagingPushFCM(config: Map<String, Any?>?): ModuleMessagingPushFCM {
        return ModuleMessagingPushFCM(
            moduleConfig = MessagingPushModuleConfig.Builder().apply {
                config?.getProperty<String>(Keys.Config.PUSH_CLICK_BEHAVIOR)
                    ?.takeIfNotBlank()
                    ?.let { value ->
                        val behavior = kotlin.runCatching {
                            enumValueOf<PushClickBehavior>(value)
                        }.getOrNull()
                        if (behavior != null) {
                            setPushClickBehavior(pushClickBehavior = behavior)
                        }
                    }
            }.build(),
        )
    }

    companion object {
        internal const val MODULE_NAME = "NativeCustomerIO"
    }
}
