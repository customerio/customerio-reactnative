package io.customer.reactnative.sdk.messaginginbox

import com.facebook.react.module.annotations.ReactModule
import com.facebook.react.uimanager.SimpleViewManager
import com.facebook.react.uimanager.ThemedReactContext
import com.facebook.react.uimanager.ViewManagerDelegate
import com.facebook.react.viewmanagers.NotificationInboxBellNativeManagerDelegate
import com.facebook.react.viewmanagers.NotificationInboxBellNativeManagerInterface

/**
 * View manager for the Visual Notification Inbox bell (just the bell; host opens its own UI).
 *
 * Registers the `onTap` direct event so taps reach the JS wrapper.
 */
@ReactModule(name = NotificationInboxBellViewManager.NAME)
class NotificationInboxBellViewManager :
    NotificationInboxBellNativeManagerInterface<ReactNotificationInboxBellView>,
    SimpleViewManager<ReactNotificationInboxBellView>() {
    private val delegate = NotificationInboxBellNativeManagerDelegate(this)

    override fun getName() = NAME
    override fun getDelegate(): ViewManagerDelegate<ReactNotificationInboxBellView> = delegate

    override fun createViewInstance(
        reactContext: ThemedReactContext
    ): ReactNotificationInboxBellView = ReactNotificationInboxBellView(reactContext)

    override fun getExportedCustomDirectEventTypeConstants(): MutableMap<String, Any> {
        val customEvents = super.getExportedCustomDirectEventTypeConstants() ?: mutableMapOf()
        customEvents[ReactNotificationInboxBellView.ON_TAP] =
            mapOf("registrationName" to ReactNotificationInboxBellView.ON_TAP)
        return customEvents
    }

    companion object {
        internal const val NAME = "NotificationInboxBellNative"
    }
}
