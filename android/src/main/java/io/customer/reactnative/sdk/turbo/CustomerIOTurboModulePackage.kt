package io.customer.reactnative.sdk.turbo

import android.view.View
import com.facebook.react.ReactPackage
import com.facebook.react.bridge.NativeModule
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.uimanager.ReactShadowNode
import com.facebook.react.uimanager.ViewManager
import io.customer.reactnative.sdk.messaginginapp.RNCIOInAppMessaging
import io.customer.reactnative.sdk.messagingpush.RNCIOPushMessaging

/**
 * ReactPackage implementation for CustomerIO TurboModules
 */
class CustomerIOTurboModulePackage : ReactPackage {

    override fun createViewManagers(
        reactContext: ReactApplicationContext
    ): List<ViewManager<out View, out ReactShadowNode<*>>> {
        return emptyList()
    }

    override fun createNativeModules(
        reactContext: ReactApplicationContext
    ): List<NativeModule> {
        // Create the push and in-app messaging modules first
        val pushMessagingModule = RNCIOPushMessaging(reactContext)
        val inAppMessagingModule = RNCIOInAppMessaging(reactContext)

        // Create the TurboModules
        val customerIOModule = CustomerIOTurboModule(
            reactContext = reactContext,
            pushMessagingModule = pushMessagingModule,
            inAppMessagingModule = inAppMessagingModule
        )
        val inAppMessagingTurboModule = InAppMessagingTurboModule(reactContext)
        val pushMessagingTurboModule = PushMessagingTurboModule(reactContext)

        // Return all modules
        return listOf(
            customerIOModule,
            inAppMessagingTurboModule,
            pushMessagingTurboModule,
            pushMessagingModule,
            inAppMessagingModule
        )
    }
}