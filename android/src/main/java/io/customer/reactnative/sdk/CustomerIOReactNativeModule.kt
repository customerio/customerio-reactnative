package io.customer.reactnative.sdk

import com.facebook.react.bridge.*
import io.customer.reactnative.sdk.extension.toMap
import io.customer.reactnative.sdk.messagingpush.RNCIOPushMessaging
import io.customer.sdk.CustomerIO
import io.customer.sdk.CustomerIOShared
import io.customer.sdk.util.Logger

class CustomerIOReactNativeModule(
    reactContext: ReactApplicationContext,
    private val pushMessagingModule: RNCIOPushMessaging,
    private val inAppMessagingModule: RNCIOInAppMessaging,
) : ReactContextBaseJavaModule(reactContext) {
    private val logger: Logger
        get() = CustomerIOShared.instance().diStaticGraph.logger
    private lateinit var customerIO: CustomerIO

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
        packageConfiguration: ReadableMap? = null,
    ) {
        if (isInstanceValid()) {
            logger.info("Customer.io instance already initialized, reinitializing")
        }

        val env = environment.toMap()
        val config = configuration?.toMap()
        val packageConfig = packageConfiguration?.toMap()

        try {
            customerIO = CustomerIOReactNativeInstance.initialize(
                context = reactApplicationContext,
                environment = env,
                configuration = config,
                packageConfig = packageConfig,
                inAppEventListener = inAppMessagingModule,
            )
            logger.info("Customer.io instance initialized successfully from app")
        } catch (ex: Exception) {
            logger.error("Failed to initialize Customer.io instance from app, ${ex.message}")
        }
    }

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

    @ReactMethod
    fun registerDeviceToken(token: String) {
        if (isNotInitialized()) return

        customerIO.registerDeviceToken(token)
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
        internal const val MODULE_NAME = "CustomerioReactnative"
    }
}
