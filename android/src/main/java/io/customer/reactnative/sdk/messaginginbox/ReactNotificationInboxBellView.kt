package io.customer.reactnative.sdk.messaginginbox

import android.content.Context
import androidx.compose.runtime.Composable
import com.facebook.react.bridge.Arguments
import io.customer.messaginginbox.NotificationInboxBell

/**
 * React Native host for the native [NotificationInboxBell] composable (just the bell).
 *
 * Emits [ON_TAP] when the user taps the bell; the JS host presents its own inbox UI.
 */
class ReactNotificationInboxBellView(context: Context) : ReactComposeHostView(context) {
    @Composable
    override fun content() {
        NotificationInboxBell(
            onClick = { emitEvent(ON_TAP, Arguments.createMap()) }
        )
    }

    companion object {
        const val ON_TAP = "onTap"
    }
}
