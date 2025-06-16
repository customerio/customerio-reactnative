package io.customer.reactnative.sdk.messaginginapp

import com.facebook.react.module.annotations.ReactModule
import com.facebook.react.uimanager.SimpleViewManager
import com.facebook.react.uimanager.ThemedReactContext
import com.facebook.react.uimanager.ViewManagerDelegate
import com.facebook.react.uimanager.annotations.ReactProp
import com.facebook.react.viewmanagers.InlineMessageNativeManagerDelegate
import com.facebook.react.viewmanagers.InlineMessageNativeManagerInterface

@ReactModule(name = InlineInAppMessageViewManager.REACT_CLASS)
class InlineInAppMessageViewManager : SimpleViewManager<ReactInlineInAppMessageView>(),
    InlineMessageNativeManagerInterface<ReactInlineInAppMessageView> {
    private val delegate = InlineMessageNativeManagerDelegate(this)

    override fun getDelegate(): ViewManagerDelegate<ReactInlineInAppMessageView> = delegate
    override fun getName(): String = REACT_CLASS

    override fun createViewInstance(context: ThemedReactContext): ReactInlineInAppMessageView {
        return ReactInlineInAppMessageView(context)
    }

    @ReactProp(name = "elementId")
    override fun setElementId(view: ReactInlineInAppMessageView, elementId: String?) {
        view.elementId = elementId
    }

    companion object {
        const val REACT_CLASS = "InlineMessageNative"
    }
}
