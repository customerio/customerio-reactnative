package io.customer.reactnative.sdk.messaginginbox

import com.facebook.react.module.annotations.ReactModule
import com.facebook.react.uimanager.SimpleViewManager
import com.facebook.react.uimanager.ThemedReactContext
import com.facebook.react.uimanager.ViewManagerDelegate
import com.facebook.react.viewmanagers.NotificationInboxViewNativeManagerDelegate
import com.facebook.react.viewmanagers.NotificationInboxViewNativeManagerInterface

/**
 * View manager for the Visual Notification Inbox message list (the Jist-rendered list,
 * embeddable in the host's own screen). No props or events; sizing comes from the JS style.
 */
@ReactModule(name = NotificationInboxViewManager.NAME)
class NotificationInboxViewManager :
    NotificationInboxViewNativeManagerInterface<ReactNotificationInboxView>,
    SimpleViewManager<ReactNotificationInboxView>() {
    private val delegate = NotificationInboxViewNativeManagerDelegate(this)

    override fun getName() = NAME
    override fun getDelegate(): ViewManagerDelegate<ReactNotificationInboxView> = delegate

    override fun createViewInstance(
        reactContext: ThemedReactContext
    ): ReactNotificationInboxView = ReactNotificationInboxView(reactContext)

    companion object {
        internal const val NAME = "NotificationInboxViewNative"
    }
}
