package io.customer.reactnative.sdk

import android.app.Application
import android.content.pm.ApplicationInfo
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactContextBaseJavaModule
import com.facebook.react.bridge.ReactMethod
import com.facebook.react.bridge.ReadableMap
import io.customer.messaginginapp.ModuleMessagingInApp
import io.customer.messagingpush.MessagingPushModuleConfig
import io.customer.messagingpush.ModuleMessagingPushFCM
import io.customer.reactnative.sdk.constant.Keys
import io.customer.reactnative.sdk.extension.*
import io.customer.sdk.CustomerIO
import io.customer.sdk.data.store.Client
import io.customer.sdk.util.CioLogLevel
import io.customer.sdk.util.Logger

class CustomerIOReactNativeModule(
    reactContext: ReactApplicationContext,
) : ReactContextBaseJavaModule(reactContext) {
    private val logger: Logger = CustomerIOReactNativeInstance.logger
    private lateinit var customerIO: CustomerIO

    init {
        val isDebuggable = 0 != reactContext.applicationInfo.flags and
                ApplicationInfo.FLAG_DEBUGGABLE
        CustomerIOReactNativeInstance.setLogLevel(
            logLevel = if (isDebuggable) CioLogLevel.DEBUG else CioLogLevel.ERROR,
        )
    }

    override fun getName(): String {
        return MODULE_NAME
    }

    private fun isInstanceValid(): Boolean {
        return ::customerIO.isInitialized
    }

    private fun isNotInitialized(): Boolean {
        val isInstanceInvalid = !isInstanceValid()
        if (isInstanceInvalid) {
            logger.error("Customer.io instance not initialized")
        }
        return isInstanceInvalid
    }

    @JvmOverloads
    @ReactMethod
    fun initialize(
        environment: ReadableMap,
        configuration: ReadableMap? = null,
        sdkVersion: String? = null,
    ) {
        if (isInstanceValid()) {
            logger.info("Customer.io instance already initialized")
            return
        }

        val env = environment.toMap()
        val config = configuration?.toMap()

        try {
            val siteId = env.getString(Keys.Environment.SITE_ID)
            val apiKey = env.getString(Keys.Environment.API_KEY)
            val region = env.getProperty<String>(
                Keys.Environment.REGION
            )?.takeIfNotBlank().toRegion()
            val organizationId = env.getProperty<String>(
                Keys.Environment.ORGANIZATION_ID
            )?.takeIfNotBlank()

            customerIO = CustomerIO.Builder(
                siteId = siteId,
                apiKey = apiKey,
                region = region,
                appContext = reactApplicationContext.applicationContext as Application,
            ).apply {
                setClient(Client.ReactNative(sdkVersion = sdkVersion ?: "n/a"))
                setupConfig(config)
                addCustomerIOModule(module = configureModuleMessagingPushFCM(config))
                if (!organizationId.isNullOrBlank()) {
                    addCustomerIOModule(module = configureModuleMessagingInApp(organizationId))
                }
            }.build()
        } catch (ex: IllegalArgumentException) {
            logger.error(ex.message ?: "$MODULE_NAME -> initialize -> IllegalArgumentException")
        }
    }

    private fun CustomerIO.Builder.setupConfig(config: Map<String, Any>?): CustomerIO.Builder {
        if (config == null) return this

        val logLevel = config.getProperty<Double>(Keys.Config.LOG_LEVEL).toCIOLogLevel()
        CustomerIOReactNativeInstance.setLogLevel(logLevel = logLevel)
        setLogLevel(level = logLevel)
        config.getProperty<String>(Keys.Config.TRACKING_API_URL)?.takeIfNotBlank()?.let { value ->
            setTrackingApiURL(value)
        }
        config.getProperty<Boolean>(Keys.Config.AUTO_TRACK_DEVICE_ATTRIBUTES)?.let { value ->
            autoTrackDeviceAttributes(shouldTrackDeviceAttributes = value)
        }
        config.getProperty<Double>(Keys.Config.BACKGROUND_QUEUE_MIN_NUMBER_OF_TASKS)?.let { value ->
            setBackgroundQueueMinNumberOfTasks(backgroundQueueMinNumberOfTasks = value.toInt())
        }
        config.getProperty<Double>(Keys.Config.BACKGROUND_QUEUE_SECONDS_DELAY)?.let { value ->
            setBackgroundQueueSecondsDelay(backgroundQueueSecondsDelay = value)
        }
        return this
    }

    private fun configureModuleMessagingPushFCM(config: Map<String, Any>?) = ModuleMessagingPushFCM(
        config = MessagingPushModuleConfig.Builder().apply {
            config?.getProperty<Boolean>(Keys.Config.AUTO_TRACK_PUSH_EVENTS)?.let { value ->
                setAutoTrackPushEvents(autoTrackPushEvents = value)
            }
        }.build(),
    )

    private fun configureModuleMessagingInApp(organizationId: String) = ModuleMessagingInApp(
        organizationId = organizationId,
    )

    @ReactMethod
    fun clearIdentify() {
        if (isNotInitialized()) return

        customerIO.clearIdentify()
    }

    @ReactMethod
    fun identify(identifier: String, attributes: ReadableMap?) {
        if (isNotInitialized()) return

        customerIO.identify(identifier, attributes.toMap())
    }

    @ReactMethod
    fun track(name: String, attributes: ReadableMap?) {
        if (isNotInitialized()) return

        customerIO.track(name, attributes.toMap())
    }

    @ReactMethod
    fun setDeviceAttributes(attributes: ReadableMap?) {
        if (isNotInitialized()) return

        customerIO.deviceAttributes = attributes.toMap()
    }

    @ReactMethod
    fun setProfileAttributes(attributes: ReadableMap?) {
        if (isNotInitialized()) return

        customerIO.profileAttributes = attributes.toMap()
    }

    @ReactMethod
    fun screen(name: String, attributes: ReadableMap?) {
        if (isNotInitialized()) return

        customerIO.screen(name, attributes.toMap())
    }

    companion object {
        internal const val MODULE_NAME = "CustomerioReactnative"
    }
}
