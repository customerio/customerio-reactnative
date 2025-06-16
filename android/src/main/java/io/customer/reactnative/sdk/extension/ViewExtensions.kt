package io.customer.reactnative.sdk.extension

import android.view.View
import com.facebook.react.bridge.ReactContext
import com.facebook.react.bridge.WritableMap
import com.facebook.react.uimanager.UIManagerHelper
import com.facebook.react.uimanager.events.Event

/**
 * Extension property to get [ReactContext] from a View.
 * Casts the view's context to ReactContext for React Native integration.
 */
internal val View.reactContext: ReactContext
    get() = context as ReactContext

/**
 * Extension property to get React UI surface ID for this view.
 * Uses [UIManagerHelper] to retrieve the surface ID from [ReactContext].
 */
private val View.reactUISurfaceId: Int
    get() = UIManagerHelper.getSurfaceId(reactContext)

/**
 * Extension function to send UI events from native Android views to React JS.
 * Retrieves the event dispatcher and dispatches the event to React Native bridge.
 *
 * @param event The event to be sent to React JS
 */
internal fun View.sendUIEventToReactJS(event: Event<*>) {
    val eventDispatcher = UIManagerHelper.getEventDispatcherForReactTag(reactContext, id)
    eventDispatcher?.dispatchEvent(event)
}

/**
 * Event class for sending UI state changes from Android views to React Native.
 * Extends the React Native Event class to provide a bridge for native-to-JS communication.
 *
 * @param view The Android view that triggered the event
 * @param eventName The name of the event to be sent to React JS
 * @param payload Optional data payload to include with the event
 */
class ReactUIStateEvent(
    view: View,
    private val eventName: String,
    private val payload: WritableMap? = null
) : Event<ReactUIStateEvent>(view.reactUISurfaceId, view.id) {
    override fun getEventName() = eventName
    override fun getEventData(): WritableMap? = payload
}
