package io.customer.reactnative.sdk.messaginginapp

import com.facebook.react.uimanager.SimpleViewManager
import com.facebook.react.uimanager.ThemedReactContext
import com.facebook.react.uimanager.annotations.ReactProp
import io.customer.messaginginapp.ui.bridge.WrapperPlatformDelegate

/**
 * Base view manager for inline in-app message components.
 *
 * Provides common functionality for both old and new React Native architecture
 * implementations, including view creation, event handling, and property management.
 */
abstract class BaseInlineInAppMessageViewManager :
    SimpleViewManager<ReactInlineInAppMessageView>() {
    override fun getName() = NAME

    override fun createViewInstance(context: ThemedReactContext): ReactInlineInAppMessageView {
        return ReactInlineInAppMessageView(context)
    }

    /**
     * This method exports custom direct event types for the inline message view.
     * It registers two custom events:
     * - onSizeChange: Triggered when the size of the inline message changes.
     * - onStateChange: Triggered when the state of the inline message changes.
     */
    override fun getExportedCustomDirectEventTypeConstants(): MutableMap<String, Any>? {
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
    fun setElementId(view: ReactInlineInAppMessageView, elementId: String?) {
        view.elementId = elementId
    }

    companion object {
        const val NAME = "InlineMessageNative"
    }
}
