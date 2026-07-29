package io.customer.reactnative.sdk.messaginginbox

import com.facebook.react.module.annotations.ReactModule
import com.facebook.react.uimanager.SimpleViewManager
import com.facebook.react.uimanager.ThemedReactContext
import com.facebook.react.uimanager.ViewManagerDelegate
import com.facebook.react.viewmanagers.NotificationInboxOverlayNativeManagerDelegate
import com.facebook.react.viewmanagers.NotificationInboxOverlayNativeManagerInterface

/**
 * View manager for the Visual Notification Inbox overlay (drop-in bell + slide-out panel).
 *
 * The Android native overlay does not currently expose a panel-presentation callback, so we
 * register no custom events here; the JS `onPanelPresentationChange` event is iOS-only for now.
 */
@ReactModule(name = NotificationInboxOverlayViewManager.NAME)
class NotificationInboxOverlayViewManager :
    NotificationInboxOverlayNativeManagerInterface<ReactNotificationInboxOverlayView>,
    SimpleViewManager<ReactNotificationInboxOverlayView>() {
    private val delegate = NotificationInboxOverlayNativeManagerDelegate(this)

    override fun getName() = NAME
    override fun getDelegate(): ViewManagerDelegate<ReactNotificationInboxOverlayView> = delegate

    override fun createViewInstance(
        reactContext: ThemedReactContext
    ): ReactNotificationInboxOverlayView = ReactNotificationInboxOverlayView(reactContext)

    companion object {
        internal const val NAME = "NotificationInboxOverlayNative"
    }
}
