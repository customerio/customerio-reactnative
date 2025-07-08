package io.customer.reactnative.sdk

import com.facebook.react.BaseReactPackage
import com.facebook.react.bridge.NativeModule
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.module.model.ReactModuleInfo
import com.facebook.react.module.model.ReactModuleInfoProvider
import com.facebook.react.uimanager.ViewManager
import io.customer.reactnative.sdk.logging.RNCIOConsoleLoggerModule
import io.customer.reactnative.sdk.messaginginapp.BaseInlineInAppMessageViewManager
import io.customer.reactnative.sdk.messaginginapp.InlineInAppMessageViewManager
import io.customer.reactnative.sdk.messaginginapp.RNCIOInAppMessaging
import io.customer.reactnative.sdk.messagingpush.RNCIOPushMessaging

class CustomerIOReactNativePackage : BaseReactPackage() {
    // Caching native modules to avoid re-creating them multiple times
    // This should be removed in the future when we switch to TurboModules
    private val nativeModules = mutableMapOf<String, NativeModule>()

    /**
     * Initializes the native modules for Customer.io React Native SDK.
     * This ensures that the modules are created only once and reused across the application.
     */
    private fun initializeNativeModules(reactContext: ReactApplicationContext) {
        CustomerIOReactNativePackageImpl.initializeNativeModules(reactContext, nativeModules)
    }

    override fun createViewManagers(reactContext: ReactApplicationContext): List<ViewManager<*, *>> {
        return CustomerIOReactNativePackageImpl.createViewManagers(reactContext)
    }

    override fun getModule(name: String, reactContext: ReactApplicationContext): NativeModule? {
        // Ensure modules are created first
        initializeNativeModules(reactContext)
        // Debugging reveals that this method is never called for ViewManagers.
        // But since ReactNative docs recommend overriding it, we do so here for ViewManagers.
        // See: https://reactnative.dev/docs/fabric-native-components-introduction?platforms=android#4-write-the-reactwebviewpackage
        return nativeModules[name] ?: when (name) {
            BaseInlineInAppMessageViewManager.NAME -> InlineInAppMessageViewManager()
            else -> null
        }
    }

    /**
     * Creates a map entry for React module registration with the given configuration.
     * Using positional arguments instead of named arguments as named args break on RN 0.76.
     */
    private fun createReactModuleInfoEntry(
        name: String,
        className: String = name,
        canOverrideExistingModule: Boolean = false,
        needsEagerInit: Boolean = false,
        isCxxModule: Boolean = false,
        isTurboModule: Boolean = false,
    ) = name to ReactModuleInfo(
        name,
        className,
        canOverrideExistingModule,
        needsEagerInit,
        isCxxModule,
        isTurboModule,
    )

    override fun getReactModuleInfoProvider() = ReactModuleInfoProvider {
        mapOf(
            createReactModuleInfoEntry(
                name = NativeCustomerIOModuleImpl.NAME,
                isTurboModule = true
            ),
            createReactModuleInfoEntry(name = RNCIOConsoleLoggerModule.NAME),
            createReactModuleInfoEntry(name = RNCIOInAppMessaging.NAME),
            createReactModuleInfoEntry(name = RNCIOPushMessaging.NAME),
            createReactModuleInfoEntry(
                name = BaseInlineInAppMessageViewManager.NAME,
                isTurboModule = true
            ),
        )
    }
}
