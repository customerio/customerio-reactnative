package io.customer.reactnative.sdk.extension

import android.view.View
import com.facebook.react.bridge.WritableMap
import com.facebook.react.uimanager.UIManagerHelper
import com.facebook.react.uimanager.events.Event

/**
 * Extension function to send UI events from native Android views to React JS.
 * Retrieves the event dispatcher and dispatches the event to React Native bridge.
 *
 * @param eventName The name of the event to be sent to React JS
 * @param payload Optional data payload to include with the event
 */
internal fun View.sendUIEventToReactJS(
    eventName: String,
    payload: WritableMap? = null,
) {
    val eventDispatcher = UIManagerHelper.getEventDispatcherForReactTag(reactContext, id)
    eventDispatcher?.dispatchEvent(UIStateEvent(this, eventName, payload))
}

/**
 * Event class for sending UI state changes from Android views to React Native.
 * Extends the React Native Event class to provide a bridge for native-to-JS communication.
 */
private class UIStateEvent(
    view: View,
    private val eventName: String,
    private val payload: WritableMap? = null
) : Event<UIStateEvent>(UIManagerHelper.getSurfaceId(view.reactContext), view.id) {
    override fun getEventName() = eventName
    override fun getEventData(): WritableMap? = payload
}
