package io.customer.reactnative.sdk.extension

import android.view.View
import com.facebook.react.bridge.WritableMap
import com.facebook.react.uimanager.events.RCTEventEmitter

/**
 * Extension function to send UI events from native Android views to React JS.
 * Old Architecture (Paper) compatible implementation using RCTEventEmitter.
 *
 * @param eventName The name of the event to be sent to React JS
 * @param payload Optional data payload to include with the event
 */
internal fun View.sendUIEventToReactJS(
    eventName: String,
    payload: WritableMap? = null,
) {
    reactContext
        .getJSModule(RCTEventEmitter::class.java)
        .receiveEvent(id, eventName, payload)
}
