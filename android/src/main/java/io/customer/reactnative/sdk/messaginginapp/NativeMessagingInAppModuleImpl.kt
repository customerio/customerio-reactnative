package io.customer.reactnative.sdk.messaginginapp

import io.customer.messaginginapp.MessagingInAppModuleConfig
import io.customer.messaginginapp.ModuleMessagingInApp
import io.customer.messaginginapp.di.inAppMessaging
import io.customer.reactnative.sdk.constant.Keys
import io.customer.reactnative.sdk.extension.getTypedValue
import io.customer.sdk.CustomerIO
import io.customer.sdk.CustomerIOBuilder
import io.customer.sdk.core.di.SDKComponent
import io.customer.sdk.data.model.Region

/**
 * Shared implementation for Customer.io In-App Messaging Native SDK module.
 * Contains the actual business logic used by both new and old architecture modules.
 */
object NativeMessagingInAppModuleImpl {
    const val NAME = "NativeCustomerIOMessagingInApp"

    private val inAppMessagingModule: ModuleMessagingInApp?
        get() = kotlin.runCatching { CustomerIO.instance().inAppMessaging() }.getOrNull()
    val inAppEventListener = ReactInAppEventListener()

    /**
     * Adds InAppMessaging module to native Android SDK based on configuration provided by customer
     * app.
     *
     * @param builder CustomerIOBuilder instance to add InAppMessaging module
     * @param config Configuration provided by customer app for InAppMessaging module
     * @param region Region to be used for InAppMessaging module
     */
    fun addNativeModuleFromConfig(
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
                setEventListener(eventListener = inAppEventListener)
            }.build(),
        )
        builder.addCustomerIOModule(module)
    }

    /**
     * Dismisses any currently displayed in-app message
     */
    fun dismissMessage() {
        inAppMessagingModule?.dismissMessage()
    }
}
