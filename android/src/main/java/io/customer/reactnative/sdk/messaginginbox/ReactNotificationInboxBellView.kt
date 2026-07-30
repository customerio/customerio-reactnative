package io.customer.reactnative.sdk.messaginginbox

import android.content.Context
import android.view.MotionEvent
import androidx.compose.runtime.Composable
import com.facebook.react.bridge.Arguments
import io.customer.messaginginbox.NotificationInboxOverlay

/**
 * React Native host for the Visual Notification Inbox bell.
 *
 * Hosts the native [NotificationInboxOverlay] composable rather than `NotificationInboxBell`: only the
 * overlay ties the bell to the SDK's own inbox panel, and the wrapper deliberately does not reimplement
 * panel presentation. Sized to the frame React Native assigns, that composition *is* a bell that opens
 * the inbox — the component wrappers expose.
 *
 * Remote branding still styles the bell (colors, icon). Branding's bell *position* has no effect here:
 * alignment resolves inside this view's bounds, so the JS host owns placement via `style`.
 *
 * [ON_TAP] is observational — the SDK opens the panel itself, so the host has nothing to do in response.
 */
class ReactNotificationInboxBellView(context: Context) : ReactComposeHostView(context) {
    @Composable
    override fun content() {
        NotificationInboxOverlay()
    }

    /**
     * Reports taps without consuming them.
     *
     * `dispatchTouchEvent` rather than `onTouchEvent`: the Compose child consumes the bell tap, so a
     * parent `onTouchEvent` would never run. Dispatching to super first keeps the gesture flowing to
     * Compose (which opens the panel); we only observe the outcome. Reporting on ACTION_UP and only
     * when the touch was consumed approximates "the bell took this tap" rather than firing for taps
     * that landed on the transparent area around it.
     */
    override fun dispatchTouchEvent(event: MotionEvent): Boolean {
        val handled = super.dispatchTouchEvent(event)
        if (handled && event.actionMasked == MotionEvent.ACTION_UP) {
            emitEvent(ON_TAP, Arguments.createMap())
        }
        return handled
    }

    companion object {
        const val ON_TAP = "onTap"
    }
}
