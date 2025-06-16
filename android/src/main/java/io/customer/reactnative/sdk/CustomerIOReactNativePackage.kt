package io.customer.reactnative.sdk

import com.facebook.react.BaseReactPackage
import com.facebook.react.bridge.NativeModule
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.module.model.ReactModuleInfo
import com.facebook.react.module.model.ReactModuleInfoProvider
import com.facebook.react.uimanager.ViewManager
import io.customer.reactnative.sdk.logging.RNCIOConsoleLoggerModule
import io.customer.reactnative.sdk.messaginginapp.InlineInAppMessageViewManager
import io.customer.reactnative.sdk.messaginginapp.RNCIOInAppMessaging
import io.customer.reactnative.sdk.messagingpush.RNCIOPushMessaging

class CustomerIOReactNativePackage : BaseReactPackage() {
    // Cache modules to ensure singleton behavior for TurboModules
    private var loggerModule: RNCIOConsoleLoggerModule? = null
    private var pushMessagingModule: RNCIOPushMessaging? = null
    private var inAppMessagingModule: RNCIOInAppMessaging? = null
    private var customerIOModule: CustomerIOReactNativeModule? = null


    private fun getOrCreateModules(reactContext: ReactApplicationContext): List<NativeModule> {
        if (loggerModule == null) {
            loggerModule = RNCIOConsoleLoggerModule(reactContext)
        }
        if (pushMessagingModule == null) {
            pushMessagingModule = RNCIOPushMessaging(reactContext)
        }
        if (inAppMessagingModule == null) {
            inAppMessagingModule = RNCIOInAppMessaging(reactContext)
        }
        if (customerIOModule == null) {
            customerIOModule = CustomerIOReactNativeModule(
                reactContext = reactContext,
                pushMessagingModule = pushMessagingModule!!,
                inAppMessagingModule = inAppMessagingModule!!,
            )
        }

        return listOf(
            loggerModule!!,
            inAppMessagingModule!!,
            pushMessagingModule!!,
            customerIOModule!!,
        )
    }

    override fun createViewManagers(reactContext: ReactApplicationContext): List<ViewManager<*, *>> {
        return listOf(InlineInAppMessageViewManager())
    }

    override fun getModule(name: String, reactContext: ReactApplicationContext): NativeModule? {
        // Ensure modules are created first
        getOrCreateModules(reactContext)

        return when (name) {
            CustomerIOReactNativeModule.NAME -> customerIOModule
            RNCIOConsoleLoggerModule.NAME -> loggerModule
            RNCIOInAppMessaging.NAME -> inAppMessagingModule
            RNCIOPushMessaging.NAME -> pushMessagingModule
            else -> null
        }
    }

    override fun getReactModuleInfoProvider(): ReactModuleInfoProvider = ReactModuleInfoProvider {
        mapOf(
            CustomerIOReactNativeModule.NAME to ReactModuleInfo(
                name = CustomerIOReactNativeModule.NAME,
                className = "io.customer.reactnative.sdk.CustomerIOReactNativeModule",
                canOverrideExistingModule = false,
                needsEagerInit = false,
                isCxxModule = false,
                isTurboModule = true,
            ),
            RNCIOConsoleLoggerModule.NAME to ReactModuleInfo(
                name = RNCIOConsoleLoggerModule.NAME,
                className = "io.customer.reactnative.sdk.logging.RNCIOConsoleLoggerModule",
                canOverrideExistingModule = false,
                needsEagerInit = false,
                isCxxModule = false,
                isTurboModule = true,
            ),
            RNCIOInAppMessaging.NAME to ReactModuleInfo(
                name = RNCIOInAppMessaging.NAME,
                className = "io.customer.reactnative.sdk.messaginginapp.RNCIOInAppMessaging",
                canOverrideExistingModule = false,
                needsEagerInit = false,
                isCxxModule = false,
                isTurboModule = true,
            ),
            RNCIOPushMessaging.NAME to ReactModuleInfo(
                name = RNCIOPushMessaging.NAME,
                className = "io.customer.reactnative.sdk.messagingpush.RNCIOPushMessaging",
                canOverrideExistingModule = false,
                needsEagerInit = false,
                isCxxModule = false,
                isTurboModule = true,
            ),
            InlineInAppMessageViewManager.REACT_CLASS to ReactModuleInfo(
                name = InlineInAppMessageViewManager.REACT_CLASS,
                className = InlineInAppMessageViewManager.REACT_CLASS,
                canOverrideExistingModule = false,
                needsEagerInit = false,
                isCxxModule = false,
                isTurboModule = true,
            ),
        )
    }
}
