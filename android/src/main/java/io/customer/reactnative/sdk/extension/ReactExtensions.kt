package io.customer.reactnative.sdk.extension

import android.view.View
import com.facebook.react.bridge.ReactContext

/**
 * Extension property to get [ReactContext] from a View.
 * Casts the view's context to ReactContext for React Native integration.
 */
internal val View.reactContext: ReactContext
    get() = context as ReactContext
