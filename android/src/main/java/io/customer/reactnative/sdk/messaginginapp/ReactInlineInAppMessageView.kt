package io.customer.reactnative.sdk.messaginginapp

import android.content.Context
import android.util.AttributeSet
import androidx.annotation.AttrRes
import androidx.annotation.StyleRes
import io.customer.messaginginapp.ui.InlineInAppMessageView
import io.customer.messaginginapp.ui.core.BaseInlineInAppMessageView

/**
 * React Native implementation of inline in-app message view.
 * Replacement for [InlineInAppMessageView] from native SDK to work seamlessly with React Native.
 * Bridges native in-app message functionality with React Native event handling and layout system.
 */
class ReactInlineInAppMessageView @JvmOverloads constructor(
    context: Context,
    attrs: AttributeSet? = null,
    @AttrRes defStyleAttr: Int = 0,
    @StyleRes defStyleRes: Int = 0
) : BaseInlineInAppMessageView<ReactInAppPlatformDelegate>(
    context, attrs, defStyleAttr, defStyleRes
) {
    override val platformDelegate = ReactInAppPlatformDelegate(view = this)

    init {
        this.layoutParams = LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.WRAP_CONTENT)
        configureView()
    }

    override fun onDetachedFromWindow() {
        super.onDetachedFromWindow()
        onViewDetached()
    }

    override fun onLoadingStarted() {
        platformDelegate.sendLoadingStateEvent(InlineInAppMessageStateEvent.LoadingStarted)
    }

    override fun onLoadingFinished() {
        platformDelegate.sendLoadingStateEvent(InlineInAppMessageStateEvent.LoadingFinished)
    }

    override fun onNoMessageToDisplay() {
        platformDelegate.sendLoadingStateEvent(InlineInAppMessageStateEvent.NoMessageToDisplay)
    }
}
