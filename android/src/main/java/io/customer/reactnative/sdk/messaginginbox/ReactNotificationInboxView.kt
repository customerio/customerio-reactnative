package io.customer.reactnative.sdk.messaginginbox

import android.content.Context
import androidx.compose.runtime.Composable
import io.customer.messaginginbox.NotificationInboxView

/**
 * React Native host for the native [NotificationInboxView] composable (the Jist-rendered
 * message list). Sizing is driven by the JS `style` prop. Message actions are handled by the
 * existing global InboxEventListener, so this component emits no per-message events.
 */
class ReactNotificationInboxView(context: Context) : ReactComposeHostView(context) {
    @Composable
    override fun content() {
        NotificationInboxView()
    }
}
