package io.customer.reactnative.sdk

import android.app.Application
import com.facebook.react.bridge.Promise
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactContextBaseJavaModule
import com.facebook.react.bridge.ReactMethod
import com.facebook.react.bridge.ReadableMap
import io.customer.reactnative.sdk.extension.toMap
import io.customer.reactnative.sdk.messagingpush.RNCIOPushMessaging
import io.customer.sdk.CustomerIO
import io.customer.sdk.CustomerIOBuilder
import io.customer.sdk.core.di.SDKComponent
import io.customer.sdk.core.util.Logger

class NativeCustomerIOModule(
    reactContext: ReactApplicationContext,
    private val pushMessagingModule: RNCIOPushMessaging,
    private val inAppMessagingModule: RNCIOInAppMessaging,
) : ReactContextBaseJavaModule(reactContext) {
    private val logger: Logger
        get() = SDKComponent.logger

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

    @JvmOverloads
    @ReactMethod
    fun initialize(
        configJson: ReadableMap,
        logLevel: String,
    ) {
        val sdkInstance = customerIOInstance
        // Checks if SDK was initialized before, which means lifecycle callbacks are already
        // registered as well.
        // SDK instance may only be initialized before when a notification was received while the
        // app was in terminated state. Checking the instance earlier helps us prevent adding
        // multiple listeners and request missed events.
        val isLifecycleCallbacksRegistered = sdkInstance != null

        if (sdkInstance != null) {
            logger.info("Customer.io instance already initialized, reinitializing")
        }

//        logger.info(configJson)

        //val packageConfig = packageConfiguration?.toMap()

        try {

            CustomerIOBuilder(
                applicationContext = reactApplicationContext as Application,
                cdpApiKey = "your_cdp_api_key"
            ).apply {
                autoTrackDeviceAttributes(true)
                autoTrackActivityScreens(false)
                build()
            }

//val newInstance = CustomerIOReactNativeInstance.initialize(
//    context = reactApplicationContext,
//    environment = env,
//    configuration = config,
//    packageConfig = packageConfig,
//    inAppEventListener = inAppMessagingModule,
//)
logger.info("Customer.io instance initialized successfully from app")
// Request lifecycle events for first initialization only as relaunching app
// in wrapper SDKs may result in reinitialization of SDK and lifecycle listener
// will already be attached in this case as they are registered to application object.
if (!isLifecycleCallbacksRegistered) {
    currentActivity?.let { activity ->
        logger.info("Requesting delayed activity lifecycle events")
//        val lifecycleCallbacks = newInstance.diGraph.activityLifecycleCallbacks
//        lifecycleCallbacks.postDelayedEventsForNonNativeActivity(activity)
    }
}
} catch (ex: Exception) {
logger.error("Failed to initialize Customer.io instance from app, ${ex.message}")
}
}

@ReactMethod
fun clearIdentify() {
customerIO()?.clearIdentify()
}

@ReactMethod
fun identify(identifier: String, attributes: ReadableMap?) {
customerIO()?.identify(identifier, attributes.toMap())
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

companion object {
internal const val MODULE_NAME = "NativeCustomerIO"
}
}
