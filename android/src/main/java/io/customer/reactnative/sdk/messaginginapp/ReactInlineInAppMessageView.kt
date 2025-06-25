package io.customer.reactnative.sdk.messaginginapp

import android.content.Context
import android.util.AttributeSet
import androidx.annotation.AttrRes
import androidx.annotation.StyleRes
import io.customer.messaginginapp.ui.InlineInAppMessageView
import io.customer.messaginginapp.ui.core.WrapperInlineView

/**
 * React Native implementation of inline in-app message view extending [WrapperInlineView].
 * Replacement for [InlineInAppMessageView] from native SDK to work seamlessly with React Native.
 * Bridges native in-app message functionality with React Native event handling and layout system.
 */
class ReactInlineInAppMessageView @JvmOverloads constructor(
    context: Context,
    attrs: AttributeSet? = null,
    @AttrRes defStyleAttr: Int = 0,
    @StyleRes defStyleRes: Int = 0
) : WrapperInlineView<ReactInAppPlatformDelegate>(
    context, attrs, defStyleAttr, defStyleRes
) {
    override val platformDelegate = ReactInAppPlatformDelegate(view = this)

    init {
        initializeView()
    }
}
