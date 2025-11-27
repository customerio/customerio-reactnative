package io.customer.reactnative.sdk.messaginginapp

import com.facebook.react.bridge.ReactApplicationContext
import io.customer.messaginginapp.MessagingInAppModuleConfig
import io.customer.messaginginapp.ModuleMessagingInApp
import io.customer.messaginginapp.di.inAppMessaging
import io.customer.reactnative.sdk.NativeCustomerIOMessagingInAppSpec
import io.customer.reactnative.sdk.constant.Keys
import io.customer.reactnative.sdk.extension.getTypedValue
import io.customer.sdk.CustomerIO
import io.customer.sdk.CustomerIOBuilder
import io.customer.sdk.core.di.SDKComponent
import io.customer.sdk.data.model.Region

/**
 * React Native module implementation for Customer.io In-App Messaging Native SDK
 * using TurboModules with new architecture.
 */
class NativeMessagingInAppModule(
    reactContext: ReactApplicationContext,
) : NativeCustomerIOMessagingInAppSpec(reactContext) {
    private val inAppMessagingModule: ModuleMessagingInApp?
        get() = kotlin.runCatching { CustomerIO.instance().inAppMessaging() }.getOrNull()

    private val inAppEventListener = ReactInAppEventListener.shared

    override fun initialize() {
        super.initialize()
        inAppEventListener.setEventEmitter { data ->
            emitOnInAppEventReceived(data)
        }
    }

    override fun invalidate() {
        inAppEventListener.clearEventEmitter()
        super.invalidate()
    }

    override fun dismissMessage() {
        inAppMessagingModule?.dismissMessage()
    }

    companion object {
        internal const val NAME = "NativeCustomerIOMessagingInApp"

        /**
         * Adds InAppMessaging module to native Android SDK based on configuration provided by customer
         * app.
         *
         * @param builder CustomerIOBuilder instance to add InAppMessaging module
         * @param config Configuration provided by customer app for InAppMessaging module
         * @param region Region to be used for InAppMessaging module
         */
        internal fun addNativeModuleFromConfig(
            builder: CustomerIOBuilder,
            config: Map<String, Any>,
            region: Region
        ) {
            val siteId = config.getTypedValue<String>(Keys.Config.SITE_ID)
            if (siteId.isNullOrBlank()) {
                SDKComponent.logger.error("Site ID is required to initialize InAppMessaging module")
                return
            }

            val module = ModuleMessagingInApp(
                MessagingInAppModuleConfig.Builder(siteId = siteId, region = region).apply {
                    setEventListener(eventListener = ReactInAppEventListener.shared)
                }.build(),
            )
            builder.addCustomerIOModule(module)
        }
    }
}
