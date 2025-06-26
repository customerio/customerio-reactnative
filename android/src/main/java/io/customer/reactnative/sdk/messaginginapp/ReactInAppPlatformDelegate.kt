package io.customer.reactnative.sdk.messaginginapp

import android.view.View
import com.facebook.react.bridge.Arguments
import io.customer.messaginginapp.ui.bridge.WrapperPlatformDelegate
import io.customer.reactnative.sdk.extension.sendUIEventToReactJS

/**
 * React Native platform delegate for in-app messaging.
 * Bridges native in-app message events to React Native components.
 *
 * @param view The native Android view hosting the in-app message
 */
class ReactInAppPlatformDelegate(
    view: View,
) : WrapperPlatformDelegate(view) {
    /**
     * Dispatches in-app message events from native Android to React Native components.
     * Converts native events to React Native UI events using the provided event name and payload.
     */
    override fun dispatchEvent(eventName: String, payload: Map<String, Any?>) {
        view.sendUIEventToReactJS(
            eventName = eventName,
            payload = Arguments.makeNativeMap(payload),
        )
    }

    // Internal helper method for dispatching events within the SDK.
    internal fun dispatchEventInternal(eventName: String, payload: Map<String, Any?>) {
        dispatchEvent(eventName, payload)
    }

    companion object {
        // Event name constant for in-app message action clicks
        const val ON_ACTION_CLICK = "onActionClick"
    }
}
