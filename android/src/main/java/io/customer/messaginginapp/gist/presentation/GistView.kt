package io.customer.messaginginapp.gist.presentation

import android.content.ActivityNotFoundException
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.net.UrlQuerySanitizer
import android.util.AttributeSet
import android.util.Base64
import android.util.DisplayMetrics
import android.util.Log
import android.widget.FrameLayout
import androidx.core.content.ContextCompat.startActivity
import com.google.gson.Gson
import io.customer.messaginginapp.gist.data.model.Message
import io.customer.messaginginapp.gist.data.model.engine.EngineWebConfiguration
import io.customer.messaginginapp.gist.presentation.engine.EngineWebView
import io.customer.messaginginapp.gist.presentation.engine.EngineWebViewListener
import java.net.URI
import java.nio.charset.StandardCharsets

class GistView @JvmOverloads constructor(
    context: Context,
    attrs: AttributeSet? = null
) : FrameLayout(context, attrs), EngineWebViewListener {

    private var engineWebView: EngineWebView? = EngineWebView(context)
    private var currentMessage: Message? = null
    private var currentRoute: String? = null
    private var firstLoad: Boolean = true
    var listener: GistViewListener? = null

    init {
        engineWebView?.let { engineWebView ->
            engineWebView.alpha = 0.0f
            engineWebView.listener = this
        }
        this.addView(engineWebView)
    }

    fun setup(message: Message) {
        currentMessage = message
        currentMessage?.let { message ->
            val engineWebConfiguration = EngineWebConfiguration(
                siteId = GistSdk.getInstance().siteId,
                dataCenter = GistSdk.getInstance().dataCenter,
                messageId = message.messageId,
                instanceId = message.instanceId,
                endpoint = GistSdk.gistEnvironment.getEngineApiUrl(),
                properties = message.properties
            )
            engineWebView?.setup(engineWebConfiguration)
        }
    }

    override fun tap(name: String, action: String, system: Boolean) {
        var shouldLogAction = true
        currentMessage?.let { message ->
            currentRoute?.let { route ->
                GistSdk.handleGistAction(message = message, currentRoute = route, action = action, name = name)
                when {
                    action.startsWith("gist://") -> {
                        val gistAction = URI(action)
                        val urlQuery = UrlQuerySanitizer(action)
                        when (gistAction.host) {
                            "close" -> {
                                shouldLogAction = false
                                Log.i(GIST_TAG, "Dismissing from action: $action")
                                GistSdk.dismissPersistentMessage(message)
                            }
                            "loadPage" -> {
                                val url = urlQuery.getValue("url")
                                val intent = Intent(Intent.ACTION_VIEW)
                                intent.data = Uri.parse(url)
                                startActivity(context, intent, null)
                            }
                            "showMessage" -> {
                                GistSdk.handleGistClosed(message)
                                val messageId = urlQuery.getValue("messageId")
                                val propertiesBase64 = urlQuery.getValue("properties")
                                val parameterBinary = Base64.decode(propertiesBase64, Base64.DEFAULT)
                                val parameterString = String(parameterBinary, StandardCharsets.UTF_8)
                                val map: Map<String, Any> = HashMap()
                                val properties = Gson().fromJson(parameterString, map.javaClass)
                                GistSdk.getInstance().showMessage(
                                    Message(messageId = messageId, properties = properties)
                                )
                            }
                            else -> {
                                shouldLogAction = false
                                Log.i(GIST_TAG, "Gist action unhandled")
                            }
                        }
                    }
                    system -> {
                        try {
                            shouldLogAction = false
                            Log.i(GIST_TAG, "Dismissing from system action: $action")
                            GistSdk.handleGistClosed(message)
                            val intent = Intent(Intent.ACTION_VIEW)
                            intent.data = Uri.parse(action)
                            intent.flags =
                                Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP
                            startActivity(context, intent, null)
                        } catch (e: ActivityNotFoundException) {
                            Log.i(GIST_TAG, "System action not handled")
                        }
                    }
                }
                if (shouldLogAction) {
                    Log.i(GIST_TAG, "Action selected: $action")
                }
            }
        }
    }

    override fun routeError(route: String) {
        currentMessage?.let { message ->
            GistSdk.handleGistError(message)
        }
    }

    override fun routeLoaded(route: String) {
        currentRoute = route
        if (firstLoad) {
            firstLoad = false
            engineWebView?.let { engineWebView ->
                engineWebView.alpha = 1.0f
            }
            currentMessage?.let { message ->
                GistSdk.handleGistLoaded(message)
            }
        }
    }

    override fun error() {
        currentMessage?.let { message ->
            GistSdk.handleGistError(message)
        }
    }

    override fun bootstrapped() {
        // Cleaning after engine web is bootstrapped and all assets downloaded.
        currentMessage?.let { message ->
            if (message.messageId == "") {
                engineWebView = null
                currentMessage = null
                listener = null
            }
        }
    }
    override fun routeChanged(newRoute: String) {}
    override fun sizeChanged(width: Double, height: Double) {
        listener?.onGistViewSizeChanged(getSizeBasedOnDPI(width.toInt()), getSizeBasedOnDPI(height.toInt()))
    }

    private fun getSizeBasedOnDPI(size: Int): Int {
        return size * context.resources.displayMetrics.densityDpi / DisplayMetrics.DENSITY_DEFAULT
    }
}

interface GistViewListener {
    fun onGistViewSizeChanged(width: Int, height: Int) {}
}
