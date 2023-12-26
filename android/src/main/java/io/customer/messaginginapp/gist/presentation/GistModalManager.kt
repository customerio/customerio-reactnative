package io.customer.messaginginapp.gist.presentation

import android.content.Intent
import android.util.Log
import com.google.gson.Gson
import io.customer.messaginginapp.gist.data.model.Message
import io.customer.messaginginapp.gist.data.model.MessagePosition

internal class GistModalManager : GistListener {
    private var currentMessage: Message? = null

    init {
        GistSdk.addListener(this)
    }

    @Synchronized internal fun showModalMessage(message: Message, position: MessagePosition? = null): Boolean {
        currentMessage?.let { currentMessage ->
            Log.i(
                GIST_TAG,
                "Message ${message.messageId} not shown, ${currentMessage.messageId} is already showing."
            )
            return false
        }

        Log.i(GIST_TAG, "Showing message: ${message.messageId}")
        currentMessage = message

        val intent = GistModalActivity.newIntent(GistSdk.application)
        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
        intent.putExtra(GIST_MESSAGE_INTENT, Gson().toJson(message))
        intent.putExtra(GIST_MODAL_POSITION_INTENT, position?.toString())
        GistSdk.application.startActivity(intent)
        return true
    }

    internal fun dismissActiveMessage() {
        currentMessage?.let { message ->
            GistSdk.dismissPersistentMessage(message)
        } ?: run {
            Log.i(GIST_TAG, "No modal messages to dismiss.")
        }
    }

    override fun onMessageDismissed(message: Message) {
        if (message.instanceId == currentMessage?.instanceId) {
            currentMessage = null
        }
    }

    override fun onError(message: Message) {
        if (message.instanceId == currentMessage?.instanceId) {
            currentMessage = null
        }
    }

    override fun embedMessage(message: Message, elementId: String) {}

    override fun onMessageShown(message: Message) {}

    override fun onAction(message: Message, currentRoute: String, action: String, name: String) {}

    internal fun clearCurrentMessage() {
        currentMessage = null
    }
}
