package io.customer.reactnative.sdk.messaginginapp

import android.view.View
import androidx.core.view.postDelayed
import com.facebook.react.bridge.Arguments
import io.customer.messaginginapp.ui.bridge.AndroidInAppPlatformDelegate
import io.customer.reactnative.sdk.extension.sendUIEventToReactJS

/**
 * React Native platform delegate for in-app messaging.
 * Bridges native in-app message events to React Native components.
 *
 * @param view The native Android view hosting the in-app message
 */
class ReactInAppPlatformDelegate(
    view: View,
) : AndroidInAppPlatformDelegate(view) {
    /**
     * Delegates view size animation to React Native instead of native animation.
     * Allows React Native to handle layout calculations and animations properly.
     */
    override fun animateViewSize(
        widthInDp: Double?,
        heightInDp: Double?,
        duration: Long?,
        onStart: (() -> Unit)?,
        onEnd: (() -> Unit)?
    ) {
        onStart?.invoke() // Start callback executes immediately

        val animDuration = duration ?: defaultAnimDuration
        val payload = Arguments.createMap()

        // Only include positive width values as rendering requires valid width to calculate layout size
        widthInDp?.takeIf { it > 0 }?.let { payload.putDouble("width", it) }
        heightInDp?.let { payload.putDouble("height", it) }
        payload.putDouble("duration", animDuration.toDouble())

        // Notify React Native of size change
        view.sendUIEventToReactJS(
            eventName = "onSizeChange",
            payload = payload,
        )

        // Schedule end callback to match animation duration
        onEnd?.let { view.postDelayed(animDuration) { it.invoke() } }
    }

    /**
     * Sends loading state changes to React Native.
     * Notifies the React component about in-app message loading progress.
     */
    fun sendLoadingStateEvent(state: InlineInAppMessageStateEvent) {
        val payload = Arguments.createMap()
        payload.putString("state", state.name)
        view.sendUIEventToReactJS(
            eventName = "onStateChange",
            payload = payload
        )
    }
}

/**
 * Loading states for inline in-app messages.
 * Used to communicate message loading progress between native and React Native.
 * See InlineInAppMessageViewCallback in native SDK for more details on how these states are used.
 */
enum class InlineInAppMessageStateEvent {
    LoadingStarted,
    LoadingFinished,
    NoMessageToDisplay
}
