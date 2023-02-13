package io.customer.reactnative.sdk

import com.facebook.react.ReactPackage
import com.facebook.react.bridge.NativeModule
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.uimanager.ViewManager

class CustomerIOReactNativePackage : ReactPackage {
    override fun createNativeModules(reactContext: ReactApplicationContext): List<NativeModule> {
        val inAppMessagingModule = RNCIOInAppMessaging(reactContext)
        return listOf(
            inAppMessagingModule,
            CustomerIOReactNativeModule(
                reactContext = reactContext,
                inAppMessagingModule = inAppMessagingModule,
            ),
        )
    }

    override fun createViewManagers(reactContext: ReactApplicationContext): List<ViewManager<*, *>> {
        return emptyList()
    }
}
