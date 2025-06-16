package io.customer.reactnative.sdk.messaginginapp

import android.view.View
import androidx.core.view.postDelayed
import com.facebook.react.bridge.Arguments
import io.customer.messaginginapp.ui.bridge.AndroidInAppPlatformDelegate
import io.customer.reactnative.sdk.extension.ReactUIStateEvent
import io.customer.reactnative.sdk.extension.sendUIEventToReactJS

class ReactInAppPlatformDelegate(
    view: View,
) : AndroidInAppPlatformDelegate(view) {
    override fun animateViewSize(
        widthInDp: Double?,
        heightInDp: Double?,
        duration: Long?,
        onStart: (() -> Unit)?,
        onEnd: (() -> Unit)?
    ) {
        // Invoke the start callback immediately
        onStart?.invoke()
        // Use default animation duration if none is provided
        val animDuration = duration ?: defaultAnimDuration
        // Prepare the payload for the event
        val payload = Arguments.createMap()
        widthInDp?.takeIf { it > 0 }?.let { payload.putDouble("width", it) }
        heightInDp?.let { payload.putDouble("height", it) }
        payload.putDouble("duration", animDuration.toDouble())
        // Instead of animating the view directly, delegate to JS component
        // to update its size so React can calculate layout correctly
        view.sendUIEventToReactJS(
            event = ReactUIStateEvent(
                view = view,
                eventName = "onSizeChange",
                payload = payload,
            )
        )
        // Post the end callback after the animation duration to simulate the animation end
        onEnd?.let { view.postDelayed(animDuration) { it.invoke() } }
    }

    /**
     * Sends a loading state event to React Native.
     * This method is used to notify React Native side about the loading state of in-app message.
     *
     * @param state The state event to be sent, indicating the loading status.
     */
    fun sendLoadingStateEvent(state: InlineInAppMessageStateEvent) {
        val payload = Arguments.createMap()
        payload.putString("state", state.name)
        view.sendUIEventToReactJS(
            event = ReactUIStateEvent(
                view = view,
                eventName = "onStateChange",
                payload = payload
            )
        )
    }
}

enum class InlineInAppMessageStateEvent {
    LoadingStarted,
    LoadingFinished,
    NoMessageToDisplay
}
