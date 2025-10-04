package io.customer.reactnative.sdk

import android.os.Build
import android.util.Log
import com.facebook.react.bridge.NativeModule
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.uimanager.ViewManager
import io.customer.reactnative.sdk.logging.NativeCustomerIOLoggingModule
import io.customer.reactnative.sdk.logging.NativeCustomerIOLoggingModuleImpl
import io.customer.reactnative.sdk.messaginginapp.InlineInAppMessageViewManager
import io.customer.reactnative.sdk.messaginginapp.NativeMessagingInAppModule
import io.customer.reactnative.sdk.messaginginapp.NativeMessagingInAppModuleImpl
import io.customer.reactnative.sdk.messagingpush.NativeMessagingPushModule
import io.customer.reactnative.sdk.messagingpush.NativeMessagingPushModuleImpl
import io.customer.reactnative.sdk.util.assertNotNull

/**
 * Registry and factory for Customer.io React Native SDK modules and view managers.
 * Provides centralized module creation for both old and new architecture.
 *
 * This object serves as the single source of truth for all TurboModule registrations
 * and their corresponding factory methods.
 */
internal object CustomerIOReactNativePackageImpl {
    private const val TAG = "[CIO]"

    /**
     * Modules that use React Native EventEmitter and crash on armeabi-v7a due to C++ TurboModule issues.
     * These modules will be skipped on armeabi/armeabi-v7a architectures.
     */
    private val EVENT_EMITTER_MODULES = setOf(
        NativeCustomerIOLoggingModuleImpl.NAME,
        NativeMessagingInAppModuleImpl.NAME
    )

    /**
     * Returns true if running on armeabi or armeabi-v7a architecture.
     * Checks only the first (most preferred) ABI.
     */
    private val isArmeabiArchitecture: Boolean by lazy {
        Build.SUPPORTED_ABIS?.firstOrNull()
            ?.lowercase()
            ?.contains("armeabi") == true
    }

    val turboModuleNames: List<String>
        get() = listOf(
            NativeCustomerIOLoggingModuleImpl.NAME,
            NativeCustomerIOModuleImpl.NAME,
            NativeMessagingInAppModuleImpl.NAME,
            NativeMessagingPushModuleImpl.NAME,
        )

    @Suppress("UNCHECKED_CAST")
    fun <M : NativeModule> createNativeModule(
        reactContext: ReactApplicationContext,
        name: String
    ): M? {
        // Prevent C++ crashes on armeabi-v7a by skipping EventEmitter-based modules
        if (isArmeabiArchitecture && name in EVENT_EMITTER_MODULES) {
            Log.w(
                TAG,
                "Module '$name' disabled on armeabi-v7a to prevent TurboModule EventEmitter crash. " +
                    "Supported ABIs: ${Build.SUPPORTED_ABIS?.joinToString()}"
            )
            return null
        }

        return when (name) {
            NativeCustomerIOLoggingModuleImpl.NAME -> NativeCustomerIOLoggingModule(reactContext)
            NativeCustomerIOModuleImpl.NAME -> NativeCustomerIOModule(reactContext = reactContext)
            NativeMessagingInAppModuleImpl.NAME -> NativeMessagingInAppModule(reactContext)
            NativeMessagingPushModuleImpl.NAME -> NativeMessagingPushModule(reactContext)
            else -> assertNotNull<NativeModule>(value = null) { "Unknown module name: $name" }
        } as? M
    }

    /**
     * Creates the list of view managers for the Customer.io React Native SDK.
     */
    fun createViewManagers(reactContext: ReactApplicationContext): List<ViewManager<*, *>> {
        return listOf(InlineInAppMessageViewManager())
    }
}
