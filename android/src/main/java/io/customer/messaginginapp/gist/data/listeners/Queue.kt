package io.customer.messaginginapp.gist.data.listeners

import android.content.Context
import android.util.Base64
import android.util.Log
import io.customer.messaginginapp.gist.data.NetworkUtilities
import io.customer.messaginginapp.gist.data.model.GistMessageProperties
import io.customer.messaginginapp.gist.data.model.Message
import io.customer.messaginginapp.gist.data.repository.GistQueueService
import io.customer.messaginginapp.gist.presentation.GIST_TAG
import io.customer.messaginginapp.gist.presentation.GistListener
import io.customer.messaginginapp.gist.presentation.GistSdk
import java.io.File
import java.util.regex.PatternSyntaxException
import kotlinx.coroutines.GlobalScope
import kotlinx.coroutines.launch
import okhttp3.Cache
import okhttp3.Headers
import okhttp3.OkHttpClient
import okhttp3.ResponseBody.Companion.toResponseBody
import retrofit2.Retrofit
import retrofit2.converter.gson.GsonConverterFactory

class Queue : GistListener {

    private var localMessageStore: MutableList<Message> = mutableListOf()
    private var shownMessageQueueIds = mutableSetOf<String>()

    init {
        GistSdk.addListener(this)
    }

    private val cacheSize = 10 * 1024 * 1024 // 10 MB
    private val cacheDirectory by lazy { File(GistSdk.application.cacheDir, "http_cache") }
    private val cache by lazy { Cache(cacheDirectory, cacheSize.toLong()) }

    private fun saveToPrefs(context: Context, key: String, value: String) {
        val prefs = context.getSharedPreferences("network_cache", Context.MODE_PRIVATE)
        prefs.edit().putString(key, value).apply()
    }

    private fun getFromPrefs(context: Context, key: String): String? {
        val prefs = context.getSharedPreferences("network_cache", Context.MODE_PRIVATE)
        return prefs.getString(key, null)
    }

    private val gistQueueService by lazy {
        // Interceptor to set up request headers like site ID, data center, and user token.
        val httpClient: OkHttpClient =
            OkHttpClient.Builder().cache(cache)
                .addInterceptor { chain ->
                    val originalRequest = chain.request()

                    val networkRequest = originalRequest.newBuilder()
                        .addHeader(NetworkUtilities.CIO_SITE_ID_HEADER, GistSdk.siteId)
                        .addHeader(NetworkUtilities.CIO_DATACENTER_HEADER, GistSdk.dataCenter)
                        .apply {
                            GistSdk.getUserToken()?.let { userToken ->
                                addHeader(
                                    NetworkUtilities.USER_TOKEN_HEADER,
                                    // The NO_WRAP flag will omit all line terminators (i.e., the output will be on one long line).
                                    Base64.encodeToString(userToken.toByteArray(), Base64.NO_WRAP)
                                )
                            }
                        }
                        .header("Cache-Control", "no-cache")
                        .build()

                    val response = chain.proceed(networkRequest)

                    when (response.code) {
                        200 -> {
                            response.body?.let { responseBody ->
                                val responseBodyString = responseBody.string()
                                saveToPrefs(
                                    GistSdk.application,
                                    originalRequest.url.toString(),
                                    responseBodyString
                                )
                                return@addInterceptor response.newBuilder().body(
                                    responseBodyString.toResponseBody(responseBody.contentType())
                                ).build()
                            }
                        }

                        304 -> {
                            val cachedResponse =
                                getFromPrefs(GistSdk.application, originalRequest.url.toString())
                            cachedResponse?.let {
                                return@addInterceptor response.newBuilder()
                                    .body(it.toResponseBody(null)).code(200).build()
                            } ?: return@addInterceptor response
                        }

                        else -> return@addInterceptor response
                    }

                    response
                }
                .build()

        Retrofit.Builder()
            .baseUrl(GistSdk.gistEnvironment.getGistQueueApiUrl())
            .addConverterFactory(GsonConverterFactory.create())
            .client(httpClient)
            .build()
            .create(GistQueueService::class.java)
    }

    internal fun fetchUserMessagesFromLocalStore() {
        handleMessages(localMessageStore)
    }

    internal fun clearUserMessagesFromLocalStore() {
        localMessageStore.clear()
    }

    internal fun fetchUserMessages() {
        GlobalScope.launch {
            try {
                Log.i(GIST_TAG, "Fetching user messages")
                val latestMessagesResponse = gistQueueService.fetchMessagesForUser()

                // To prevent us from showing expired / revoked messages, clear user messages from local queue.
                clearUserMessagesFromLocalStore()
                if (latestMessagesResponse.code() == 204) {
                    // No content, don't do anything
                    Log.i(GIST_TAG, "No messages found for user")
                } else if (latestMessagesResponse.isSuccessful) {
                    Log.i(
                        GIST_TAG,
                        "Found ${latestMessagesResponse.body()?.count()} messages for user"
                    )
                    latestMessagesResponse.body()?.let { handleMessages(it) }
                }

                // Check if the polling interval changed and update timer.
                updatePollingInterval(latestMessagesResponse.headers())
            } catch (e: Exception) {
                Log.e(
                    GIST_TAG,
                    "Error fetching messages: ${e.message}"
                )
            }
        }
    }

    private fun updatePollingInterval(headers: Headers) {
        headers["X-Gist-Queue-Polling-Interval"]?.toIntOrNull()?.let { pollingIntervalSeconds ->
            if (pollingIntervalSeconds > 0) {
                val newPollingIntervalMilliseconds = (pollingIntervalSeconds * 1000).toLong()
                if (newPollingIntervalMilliseconds != GistSdk.pollInterval) {
                    GistSdk.pollInterval = newPollingIntervalMilliseconds
                    // Queue check fetches messages again and could result in infinite loop.
                    GistSdk.observeMessagesForUser(true)
                    Log.i(GIST_TAG, "Polling interval changed to: $pollingIntervalSeconds seconds")
                }
            }
        }
    }

    private fun handleMessages(messages: List<Message>) {
        // Sorting messages by priority and placing nulls last
        val sortedMessages = messages.sortedWith(compareBy(nullsLast()) { it.priority })
        for (message in sortedMessages) {
            processMessage(message)
        }
    }

    private fun processMessage(message: Message) {
        if (message.queueId != null && shownMessageQueueIds.contains(message.queueId)) {
            Log.i(GIST_TAG, "Duplicate message ${message.queueId} skipped")
            return
        }

        val gistProperties = GistMessageProperties.getGistProperties(message)
        gistProperties.routeRule?.let { routeRule ->
            try {
                if (!routeRule.toRegex().matches(GistSdk.currentRoute)) {
                    Log.i(
                        GIST_TAG,
                        "Message route: $routeRule does not match current route: ${GistSdk.currentRoute}"
                    )
                    addMessageToLocalStore(message)
                    return
                }
            } catch (e: PatternSyntaxException) {
                Log.i(GIST_TAG, "Invalid route rule regex: $routeRule")
                return
            }
        }
        gistProperties.elementId?.let { elementId ->
            Log.i(
                GIST_TAG,
                "Embedding message from queue with queue id: ${message.queueId}"
            )
            GistSdk.handleEmbedMessage(message, elementId)
        } ?: run {
            Log.i(
                GIST_TAG,
                "Showing message from queue with queue id: ${message.queueId}"
            )
            GistSdk.showMessage(message)
        }
    }

    internal fun logView(message: Message) {
        GlobalScope.launch {
            try {
                if (message.queueId != null) {
                    Log.i(
                        GIST_TAG,
                        "Logging view for user message: ${message.messageId}, with queue id: ${message.queueId}"
                    )
                    shownMessageQueueIds.add(message.queueId)
                    removeMessageFromLocalStore(message)
                    gistQueueService.logUserMessageView(message.queueId)
                } else {
                    Log.i(GIST_TAG, "Logging view for message: ${message.messageId}")
                    gistQueueService.logMessageView(message.messageId)
                }
            } catch (e: Exception) {
                Log.e(GIST_TAG, "Failed to log message view: ${e.message}", e)
            }
        }
    }

    private fun addMessageToLocalStore(message: Message) {
        val localMessage =
            localMessageStore.find { localMessage -> localMessage.queueId == message.queueId }
        if (localMessage == null) {
            localMessageStore.add(message)
        }
    }

    private fun removeMessageFromLocalStore(message: Message) {
        localMessageStore.removeAll { it.queueId == message.queueId }
    }

    override fun onMessageShown(message: Message) {
        val gistProperties = GistMessageProperties.getGistProperties(message)
        if (gistProperties.persistent) {
            Log.i(GIST_TAG, "Persistent message shown: ${message.messageId}, skipping logging view")
        } else {
            logView(message)
        }
    }

    override fun embedMessage(message: Message, elementId: String) {}

    override fun onMessageDismissed(message: Message) {}

    override fun onError(message: Message) {}

    override fun onAction(message: Message, currentRoute: String, action: String, name: String) {}
}
