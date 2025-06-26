package io.customer.reactnative.sdk.messaginginapp

import com.facebook.react.module.annotations.ReactModule
import com.facebook.react.uimanager.ViewManagerDelegate
import com.facebook.react.viewmanagers.InlineMessageNativeManagerDelegate
import com.facebook.react.viewmanagers.InlineMessageNativeManagerInterface

@ReactModule(name = BaseInlineInAppMessageViewManager.NAME)
class InlineInAppMessageViewManager : BaseInlineInAppMessageViewManager(),
    InlineMessageNativeManagerInterface<ReactInlineInAppMessageView> {
    private val delegate = InlineMessageNativeManagerDelegate(this)

    override fun getDelegate(): ViewManagerDelegate<ReactInlineInAppMessageView> = delegate
}
