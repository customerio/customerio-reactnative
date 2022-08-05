package io.customer.reactnative.sdk

import android.app.Application
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactContextBaseJavaModule
import com.facebook.react.bridge.ReactMethod
import com.facebook.react.bridge.ReadableMap
import io.customer.sdk.CustomerIO
import io.customer.sdk.data.model.Region
import io.customer.sdk.util.CioLogLevel
import io.customer.sdk.util.Logger

class CustomerIOReactNativeModule(
    reactApplicationContext: ReactApplicationContext,
) : ReactContextBaseJavaModule(reactApplicationContext) {
    private val application: Application = reactApplicationContext.applicationContext as Application
    private lateinit var customerIO: CustomerIO
    private val logger: Logger by lazy { customerIO.diGraph.logger }

    override fun getName(): String {
        return "CustomerioReactnative"
    }

    private fun isInitialized(): Boolean {
        return ::customerIO.isInitialized
    }

    private fun isConfigurationsPending(): Boolean {
        val isPending = !isInitialized()
        if (isPending) {
            logger.error("Customer.io instance not initialized".withLogsPrefix())
        }
        return isPending
    }

    @JvmOverloads
    @ReactMethod
    fun initialize(
        siteId: String,
        apiKey: String,
        region: String? = null,
        attributes: ReadableMap? = null
    ) {
        if (isInitialized()) {
            logger.info("Customer.io instance already initialized".withLogsPrefix())
            return
        }

        customerIO = CustomerIO.Builder(
            siteId = siteId,
            apiKey = apiKey,
            region = region.toRegion() ?: Region.US,
            appContext = application,
        ).setupConfig(attributes).build()
    }

    private inline fun <reified T> Map<String, Any>.getReactProperty(key: String): T? = try {
        getReactPropertyUnsafe(key)
    } catch (ex: IllegalArgumentException) {
        logger.error(ex.message.withLogsPrefix())
        null
    }

    private fun CustomerIO.Builder.setupConfig(attributes: ReadableMap?): CustomerIO.Builder {
        if (attributes == null) return this
        val map = attributes.toMap()

        setLogLevel(
            level = map.getReactProperty<Int>(
                key = Constants.Keys.Config.LOG_LEVEL
            )?.toCIOLogLevel() ?: CioLogLevel.NONE
        )
        map.getReactProperty<String>(Constants.Keys.Config.TRACKING_API_URL)?.let { value ->
            setTrackingApiURL(value)
        }
        map.getReactProperty<Boolean>(
            key = Constants.Keys.Config.AUTO_TRACK_DEVICE_ATTRIBUTES
        )?.let { value ->
            autoTrackDeviceAttributes(shouldTrackDeviceAttributes = value)
        }
        map.getReactProperty<Boolean>(
            key = Constants.Keys.Config.AUTO_TRACK_PUSH_EVENTS
        )?.let { value ->
            setAutoTrackPushEvents(autoTrackPushEvents = value)
        }
        map.getReactProperty<Int>(
            key = Constants.Keys.Config.BACKGROUND_QUEUE_MIN_NUMBER_OF_TASKS
        )?.let { value ->
            setBackgroundQueueMinNumberOfTasks(backgroundQueueMinNumberOfTasks = value)
        }
        map.getReactProperty<Double>(
            key = Constants.Keys.Config.BACKGROUND_QUEUE_SECONDS_DELAY
        )?.let { value ->
            setBackgroundQueueSecondsDelay(backgroundQueueSecondsDelay = value)
        }
        return this
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
