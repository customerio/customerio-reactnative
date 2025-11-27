package io.customer.reactnative.sdk.messaginginapp

import com.facebook.react.module.annotations.ReactModule
import com.facebook.react.uimanager.SimpleViewManager
import com.facebook.react.uimanager.ThemedReactContext
import com.facebook.react.uimanager.ViewManagerDelegate
import com.facebook.react.uimanager.annotations.ReactProp
import com.facebook.react.viewmanagers.InlineMessageNativeManagerDelegate
import com.facebook.react.viewmanagers.InlineMessageNativeManagerInterface
import io.customer.messaginginapp.ui.bridge.WrapperPlatformDelegate

/**
 * Base view manager for inline in-app message components.
 *
 * Provides common functionality for both old and new React Native architecture
 * implementations, including view creation, event handling, and property management.
 */
@ReactModule(name = InlineInAppMessageViewManager.NAME)
class InlineInAppMessageViewManager :
    InlineMessageNativeManagerInterface<ReactInlineInAppMessageView>,
    SimpleViewManager<ReactInlineInAppMessageView>() {
    private val delegate = InlineMessageNativeManagerDelegate(this)

    override fun getName() = NAME
    override fun getDelegate(): ViewManagerDelegate<ReactInlineInAppMessageView> = delegate

    override fun createViewInstance(reactContext: ThemedReactContext): ReactInlineInAppMessageView {
        return ReactInlineInAppMessageView(reactContext)
    }

    /**
     * This method exports custom direct event types for the inline message view.
     * It registers two custom events:
     * - onSizeChange: Triggered when the size of the inline message changes.
     * - onStateChange: Triggered when the state of the inline message changes.
     */
    override fun getExportedCustomDirectEventTypeConstants(): Map<String?, Any?> {
        val customEvents = super.getExportedCustomDirectEventTypeConstants() ?: mutableMapOf()
        val registerCustomEvent = { eventName: String ->
            customEvents.put(eventName, mapOf("registrationName" to eventName))
        }
        registerCustomEvent(WrapperPlatformDelegate.ON_SIZE_CHANGE)
        registerCustomEvent(WrapperPlatformDelegate.ON_STATE_CHANGE)
        registerCustomEvent(ReactInAppPlatformDelegate.ON_ACTION_CLICK)
        return customEvents
    }

    @ReactProp(name = "elementId")
    override fun setElementId(view: ReactInlineInAppMessageView?, value: String?) {
        view?.elementId = value
    }

    companion object {
        internal const val NAME = "InlineMessageNative"
    }
}
