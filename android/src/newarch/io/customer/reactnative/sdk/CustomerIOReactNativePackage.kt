package io.customer.reactnative.sdk

import com.facebook.react.BaseReactPackage
import com.facebook.react.bridge.NativeModule
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.module.model.ReactModuleInfo
import com.facebook.react.module.model.ReactModuleInfoProvider
import com.facebook.react.uimanager.ViewManager
import io.customer.reactnative.sdk.messaginginapp.BaseInlineInAppMessageViewManager
import io.customer.reactnative.sdk.messaginginapp.InlineInAppMessageViewManager

class CustomerIOReactNativePackage : BaseReactPackage() {
    override fun createViewManagers(reactContext: ReactApplicationContext): List<ViewManager<*, *>> {
        return CustomerIOReactNativePackageImpl.createViewManagers(reactContext)
    }

    override fun getModule(name: String, reactContext: ReactApplicationContext): NativeModule? {
        // Debugging reveals that this method is never called for ViewManagers.
        // But since ReactNative docs recommend overriding it, we do so here for ViewManagers.
        // See: https://reactnative.dev/docs/fabric-native-components-introduction?platforms=android#4-write-the-reactwebviewpackage
        return when (name) {
            BaseInlineInAppMessageViewManager.NAME -> InlineInAppMessageViewManager()
            else -> CustomerIOReactNativePackageImpl.createNativeModule(reactContext, name)
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

    override fun getReactModuleInfoProvider() = ReactModuleInfoProvider {
        buildMap {
            // Register TurboModules
            CustomerIOReactNativePackageImpl.turboModuleNames.forEach { moduleName ->
                put(moduleName, createReactModuleInfo(name = moduleName))
            }

            // Register ViewManagers
            val viewManagerName = BaseInlineInAppMessageViewManager.NAME
            val viewManagerInfo = createReactModuleInfo(name = viewManagerName)
            put(viewManagerName, viewManagerInfo)
        }
    }
}
