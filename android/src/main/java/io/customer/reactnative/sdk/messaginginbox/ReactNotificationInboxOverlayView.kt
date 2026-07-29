package io.customer.reactnative.sdk.messaginginbox

import android.content.Context
import androidx.compose.runtime.Composable
import io.customer.messaginginbox.NotificationInboxOverlay

/**
 * React Native host for the native [NotificationInboxOverlay] composable (drop-in floating
 * bell + slide-out panel).
 *
 * NOTE: The Android native overlay does not currently expose a panel-presentation callback,
 * so the JS `onPanelPresentationChange` event is iOS-only for now (see DEVELOPING_LOCALLY.md).
 */
class ReactNotificationInboxOverlayView(context: Context) : ReactComposeHostView(context) {
    @Composable
    override fun content() {
        NotificationInboxOverlay()
    }
}
