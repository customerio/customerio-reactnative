package io.customer.reactnative.sdk

import com.facebook.react.BaseReactPackage
import com.facebook.react.bridge.NativeModule
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.module.model.ReactModuleInfo
import com.facebook.react.module.model.ReactModuleInfoProvider
import com.facebook.react.uimanager.ViewManager
import io.customer.reactnative.sdk.logging.NativeCustomerIOLoggingModule
import io.customer.reactnative.sdk.messaginginapp.InlineInAppMessageViewManager
import io.customer.reactnative.sdk.messaginginapp.NativeMessagingInAppModule
import io.customer.reactnative.sdk.messagingpush.NativeMessagingPushModule
import io.customer.reactnative.sdk.util.assertNotNull

/**
 * React Native package for Customer.io SDK that registers all TurboModules and ViewManagers.
 * Implements new architecture support for React Native.
 */
class CustomerIOReactNativePackage : BaseReactPackage() {
    /**
     * Creates the list of view managers for the Customer.io React Native SDK.
     */
    override fun createViewManagers(reactContext: ReactApplicationContext): List<ViewManager<*, *>> {
        return listOf(InlineInAppMessageViewManager())
    }

    override fun getModule(name: String, reactContext: ReactApplicationContext): NativeModule? {
        // Debugging reveals that this method is never called for ViewManagers.
        // But since ReactNative docs recommend overriding it, we do so here for ViewManagers.
        // See: https://reactnative.dev/docs/fabric-native-components-introduction?platforms=android#4-write-the-reactwebviewpackage
        return when (name) {
            InlineInAppMessageViewManager.NAME -> InlineInAppMessageViewManager()
            NativeCustomerIOLoggingModule.NAME -> NativeCustomerIOLoggingModule(reactContext)
            NativeCustomerIOModule.NAME -> NativeCustomerIOModule(reactContext = reactContext)
            NativeMessagingInAppModule.NAME -> NativeMessagingInAppModule(reactContext)
            NativeMessagingPushModule.NAME -> NativeMessagingPushModule(reactContext)
            else -> assertNotNull<NativeModule>(value = null) { "Unknown module name: $name" }
        }
    }

    /**
     * Creates a ReactModuleInfo for React module registration with the given configuration.
     * Using positional arguments instead of named arguments as named args break on RN 0.76.
     */
    private fun createReactModuleInfo(
        name: String,
        className: String = name,
        canOverrideExistingModule: Boolean = false,
        needsEagerInit: Boolean = false,
        isCxxModule: Boolean = false,
        isTurboModule: Boolean = true,
    ) = ReactModuleInfo(
        name,
        className,
        canOverrideExistingModule,
        needsEagerInit,
        isCxxModule,
        isTurboModule,
    )

    override fun getReactModuleInfoProvider(): ReactModuleInfoProvider {
        // List of all Fabric ViewManagers and TurboModules registered in this package.
        // Used by React Native to identify and instantiate the modules.
        val moduleNames: List<String> = listOf(
            InlineInAppMessageViewManager.NAME,
            NativeCustomerIOLoggingModule.NAME,
            NativeCustomerIOModule.NAME,
            NativeMessagingInAppModule.NAME,
            NativeMessagingPushModule.NAME,
        )
        return ReactModuleInfoProvider {
            // Register all ViewManagers and TurboModules
            moduleNames.associateWith { moduleName ->
                createReactModuleInfo(name = moduleName)
            }
        }
    }
}
