package io.customer.messaginginapp.gist.presentation.engine

import android.annotation.SuppressLint
import android.content.Context
import android.graphics.Color
import android.net.http.SslError
import android.util.AttributeSet
import android.util.Base64
import android.util.Log
import android.webkit.*
import android.widget.FrameLayout
import com.google.gson.Gson
import io.customer.messaginginapp.gist.data.model.engine.EngineWebConfiguration
import io.customer.messaginginapp.gist.presentation.GIST_TAG
import io.customer.messaginginapp.gist.presentation.GistSdk
import io.customer.messaginginapp.gist.utilities.ElapsedTimer
import java.io.UnsupportedEncodingException
import java.util.*

internal class EngineWebView @JvmOverloads constructor(
    context: Context,
    attrs: AttributeSet? = null
) : FrameLayout(context, attrs), EngineWebViewListener {

    var listener: EngineWebViewListener? = null
    private var timer: Timer? = null
    private var timerTask: TimerTask? = null
    private var webView: WebView? = null
    private var elapsedTimer: ElapsedTimer = ElapsedTimer()

    init {
        // exception handling is required for webview in-case webview is not supported in the device
        try {
            webView = WebView(context)
            this.addView(webView)
        } catch (e: Exception) {
            Log.e(GIST_TAG, "Error while creating EngineWebView: ${e.message}")
        }
    }

    @SuppressLint("SetJavaScriptEnabled")
    fun setup(configuration: EngineWebConfiguration) {
        setupTimeout()
        val jsonString = Gson().toJson(configuration)
        encodeToBase64(jsonString)?.let { options ->
            elapsedTimer.start("Engine render for message: ${configuration.messageId}")
            val messageUrl =
                "${GistSdk.gistEnvironment.getGistRendererUrl()}/index.html?options=$options"
            Log.i(GIST_TAG, "Rendering message with URL: $messageUrl")
            webView?.let {
                it.loadUrl(messageUrl)
                it.settings.javaScriptEnabled = true
                it.settings.allowFileAccess = true
                it.settings.allowContentAccess = true
                it.settings.domStorageEnabled = true
                it.settings.textZoom = 100
                it.setBackgroundColor(Color.TRANSPARENT)
                it.addJavascriptInterface(EngineWebViewInterface(this), "appInterface")

                it.webViewClient = object : WebViewClient() {
                    override fun onPageFinished(view: WebView, url: String?) {
                        view.loadUrl("javascript:window.parent.postMessage = function(message) {window.appInterface.postMessage(JSON.stringify(message))}")
                    }

                    override fun shouldOverrideUrlLoading(view: WebView, url: String): Boolean {
                        return !url.startsWith("https://code.gist.build")
                    }

                    override fun onReceivedError(
                        view: WebView?,
                        errorCod: Int,
                        description: String,
                        failingUrl: String?
                    ) {
                        listener?.error()
                    }

                    override fun onReceivedHttpError(
                        view: WebView?,
                        request: WebResourceRequest?,
                        errorResponse: WebResourceResponse?
                    ) {
                        listener?.error()
                    }

                    override fun onReceivedError(
                        view: WebView?,
                        request: WebResourceRequest?,
                        error: WebResourceError?
                    ) {
                        listener?.error()
                    }

                    override fun onReceivedSslError(
                        view: WebView?,
                        handler: SslErrorHandler?,
                        error: SslError?
                    ) {
                        listener?.error()
                    }
                }
            }
        } ?: run {
            listener?.error()
        }
    }

    private fun encodeToBase64(text: String): String? {
        val data: ByteArray?
        try {
            data = text.toByteArray(charset("UTF-8"))
        } catch (ex: UnsupportedEncodingException) {
            Log.e(GIST_TAG, "Unsupported encoding exception")
            return null
        }
        return Base64.encodeToString(data, Base64.URL_SAFE)
    }

    private fun setupTimeout() {
        timerTask = object : TimerTask() {
            override fun run() {
                if (timer != null) {
                    Log.i(GIST_TAG, "Message global timeout, cancelling display.")
                    listener?.error()
                    stopTimer()
                }
            }
        }
        timer = Timer()
        timer?.schedule(timerTask, 5000)
    }

    override fun bootstrapped() {
        stopTimer()
        listener?.bootstrapped()
    }

    override fun tap(name: String, action: String, system: Boolean) {
        listener?.tap(name, action, system)
    }

    override fun routeChanged(newRoute: String) {
        elapsedTimer.start("Engine render for message: $newRoute")
        listener?.routeChanged(newRoute)
    }

    override fun routeError(route: String) {
        listener?.routeError(route)
    }

    override fun routeLoaded(route: String) {
        elapsedTimer.end()
        listener?.routeLoaded(route)
    }

    override fun sizeChanged(width: Double, height: Double) {
        listener?.sizeChanged(width, height)
    }

    override fun error() {
        listener?.error()
    }

    private fun stopTimer() {
        timerTask?.cancel()
        timer?.cancel()
        timer?.purge()
        timer = null
    }
}
