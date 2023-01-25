package io.customer.reactnative.sdk

import com.facebook.react.ReactPackage
import com.facebook.react.bridge.NativeModule
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.uimanager.ViewManager

class CustomerIOReactNativePackage : ReactPackage {
    override fun createNativeModules(reactContext: ReactApplicationContext): List<NativeModule> {
        val inAppEventListener = RNCIOInAppEventListener(reactContext)
        return listOf(
            inAppEventListener,
            CustomerIOReactNativeModule(
                reactContext = reactContext,
                inAppEventListener = inAppEventListener,
            ),
        )
    }

    override fun createViewManagers(reactContext: ReactApplicationContext): List<ViewManager<*, *>> {
        return emptyList()
    }
}
