package io.customer.reactnative.sdk

import com.facebook.react.bridge.NativeModule
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.uimanager.ViewManager
import io.customer.reactnative.sdk.logging.RNCIOConsoleLoggerModule
import io.customer.reactnative.sdk.messaginginapp.InlineInAppMessageViewManager
import io.customer.reactnative.sdk.messaginginapp.RNCIOInAppMessaging
import io.customer.reactnative.sdk.messagingpush.RNCIOPushMessaging

/**
 * Shared implementation of the [CustomerIOReactNativePackage] for common functionality in
 * both the new and old architecture.
 */
object CustomerIOReactNativePackageImpl {
    /**
     * Creates and initializes all native modules for the Customer.io React Native SDK.
     */
    private fun createAndInitializeModules(
        reactContext: ReactApplicationContext,
        nativeModules: MutableMap<String, NativeModule>? = null
    ): Map<String, NativeModule> {
        val modules = nativeModules ?: mutableMapOf()

        val loggerModule = modules.getOrPut(RNCIOConsoleLoggerModule.NAME) {
            RNCIOConsoleLoggerModule(reactContext)
        }
        val pushMessagingModule = modules.getOrPut(RNCIOPushMessaging.NAME) {
            RNCIOPushMessaging(reactContext)
        } as RNCIOPushMessaging
        val inAppMessagingModule = modules.getOrPut(RNCIOInAppMessaging.NAME) {
            RNCIOInAppMessaging(reactContext)
        } as RNCIOInAppMessaging
        val mainModule = modules.getOrPut(CustomerIOReactNativeModule.NAME) {
            CustomerIOReactNativeModule(
                reactContext = reactContext,
                pushMessagingModule = pushMessagingModule,
                inAppMessagingModule = inAppMessagingModule,
            )
        }

        return mapOf(
            RNCIOConsoleLoggerModule.NAME to loggerModule,
            RNCIOPushMessaging.NAME to pushMessagingModule,
            RNCIOInAppMessaging.NAME to inAppMessagingModule,
            CustomerIOReactNativeModule.NAME to mainModule
        )
    }

    /**
     * Creates the list of native modules for the Customer.io React Native SDK.
     */
    fun createNativeModules(reactContext: ReactApplicationContext): List<NativeModule> {
        // Since order does not matter, we can just return the values of the map
        return createAndInitializeModules(reactContext).values.toList()
    }

    /**
     * Creates the list of view managers for the Customer.io React Native SDK.
     */
    fun createViewManagers(reactContext: ReactApplicationContext): List<ViewManager<*, *>> {
        return listOf(InlineInAppMessageViewManager())
    }

    /**
     * Initializes native modules with caching to avoid re-creating them multiple times.
     * This should be removed in the future when we switch to TurboModules.
     */
    fun initializeNativeModules(
        reactContext: ReactApplicationContext,
        nativeModules: MutableMap<String, NativeModule>
    ) {
        createAndInitializeModules(reactContext, nativeModules)
    }
}
