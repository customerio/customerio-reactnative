package io.customer.reactnative.sdk

import com.facebook.react.ReactPackage
import com.facebook.react.bridge.NativeModule
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.uimanager.ViewManager
import io.customer.reactnative.sdk.messagingpush.RNCIOPushMessaging

class CustomerIOReactNativePackage : ReactPackage {
    override fun createNativeModules(reactContext: ReactApplicationContext): List<NativeModule> {
        val pushMessagingModule = RNCIOPushMessaging(reactContext)
        val inAppMessagingModule = RNCIOInAppMessaging(reactContext)
        val loggerModule = CustomerIOReactNativeLoggingEmitter(reactContext)
        return listOf(
            inAppMessagingModule,
            pushMessagingModule,
            loggerModule,
            NativeCustomerIOModule(
                reactContext = reactContext,
                pushMessagingModule = pushMessagingModule,
                inAppMessagingModule = inAppMessagingModule,
            ),
        )
    }

    override fun createViewManagers(reactContext: ReactApplicationContext): List<ViewManager<*, *>> {
        return emptyList()
    }
}