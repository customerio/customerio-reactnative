package io.customer.reactnative.sdk.messaginginbox

import android.content.Context
import android.view.Choreographer
import android.view.View
import android.widget.FrameLayout
import androidx.compose.runtime.Composable
import androidx.compose.ui.platform.ComposeView
import com.facebook.react.bridge.WritableMap
import io.customer.reactnative.sdk.extension.sendUIEventToReactJS

/**
 * Base React Native view that hosts a Jetpack Compose [content] inside a [ComposeView].
 *
 * Mirrors the role that the native SDK's `WrapperInlineView` plays for inline in-app
 * messages, but the Visual Notification Inbox components are plain `@Composable`s, so we
 * host them directly in a [ComposeView] rather than going through an inline-message wrapper.
 *
 * Subclasses provide the composable via [content] and emit events with [emitEvent].
 *
 * Layout note: React Native (Yoga) lays this view out, so the [ComposeView] is sized to the
 * bounds RN assigns. Because RN children measured by native code don't always re-trigger a
 * layout pass, we schedule a manual measure/layout via the [Choreographer] whenever the view
 * is attached, matching how other RN-hosted native views keep themselves laid out.
 */
abstract class ReactComposeHostView(context: Context) : FrameLayout(context) {

    private val composeView: ComposeView = ComposeView(context).apply {
        layoutParams = LayoutParams(
            LayoutParams.MATCH_PARENT,
            LayoutParams.MATCH_PARENT
        )
        setContent { content() }
    }

    /** The Compose UI hosted by this view. Implemented by each concrete inbox component. */
    @Composable
    protected abstract fun content()

    init {
        addView(composeView)
    }

    /**
     * Dispatches a UI event back to the JS side using the React Native event dispatcher.
     *
     * @param eventName name registered in the view manager's
     *   `getExportedCustomDirectEventTypeConstants`.
     * @param payload optional event data.
     */
    protected fun emitEvent(eventName: String, payload: WritableMap? = null) {
        sendUIEventToReactJS(eventName = eventName, payload = payload)
    }

    /**
     * React Native lays out views off the main Android layout pass, so manually re-run
     * measure + layout against the bounds RN assigned. Without this, native children of
     * RN-managed views can render with a zero size.
     */
    override fun requestLayout() {
        super.requestLayout()
        post(measureAndLayout)
    }

    private val measureAndLayout = Runnable {
        measure(
            MeasureSpec.makeMeasureSpec(width, MeasureSpec.EXACTLY),
            MeasureSpec.makeMeasureSpec(height, MeasureSpec.EXACTLY)
        )
        layout(left, top, right, bottom)
    }

    private fun View.post(action: Runnable) {
        Choreographer.getInstance().postFrameCallback { action.run() }
    }
}
