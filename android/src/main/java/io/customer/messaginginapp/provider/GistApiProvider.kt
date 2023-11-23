package io.customer.messaginginapp.provider

import android.app.Application
import io.customer.messaginginapp.gist.data.model.GistMessageProperties
import io.customer.messaginginapp.gist.data.model.Message
import io.customer.messaginginapp.gist.presentation.GistListener
import io.customer.messaginginapp.gist.presentation.GistSdk

/**
 * Wrapper around Gist Apis
 */
internal interface GistApi {
    fun initProvider(application: Application, siteId: String, dataCenter: String)
    fun setUserToken(userToken: String)
    fun setCurrentRoute(route: String)
    fun clearUserToken()
    fun addListener(listener: GistListener)
    fun dismissMessage()
    fun subscribeToEvents(
        onMessageShown: (deliveryId: String) -> Unit,
        onAction: (deliveryId: String?, currentRoute: String, action: String, name: String) -> Unit,
        onError: (errorMessage: String) -> Unit
    )
}

internal class GistApiProvider : GistApi {
    override fun initProvider(application: Application, siteId: String, dataCenter: String) {
        GistSdk.init(
            application = application,
            siteId = siteId,
            dataCenter = dataCenter
        )
    }

    override fun setUserToken(userToken: String) {
        GistSdk.setUserToken(userToken)
    }

    override fun setCurrentRoute(route: String) {
        GistSdk.setCurrentRoute(route)
    }

    override fun clearUserToken() {
        GistSdk.clearUserToken()
    }

    override fun addListener(listener: GistListener) {
        GistSdk.addListener(listener)
    }

    override fun dismissMessage() {
        GistSdk.dismissMessage()
    }

    override fun subscribeToEvents(
        onMessageShown: (String) -> Unit,
        onAction: (deliveryId: String?, currentRoute: String, action: String, name: String) -> Unit,
        onError: (message: String) -> Unit
    ) {
        GistSdk.addListener(object : GistListener {
            override fun embedMessage(message: Message, elementId: String) {
            }

            override fun onAction(
                message: Message,
                currentRoute: String,
                action: String,
                name: String
            ) {
                val deliveryID = GistMessageProperties.getGistProperties(message).campaignId
                onAction(deliveryID, currentRoute, action, name)
            }

            override fun onError(message: Message) {
                onError(message.toString())
            }

            override fun onMessageDismissed(message: Message) {
            }

            override fun onMessageShown(message: Message) {
                val deliveryID = GistMessageProperties.getGistProperties(message).campaignId
                deliveryID?.let { onMessageShown(it) }
            }
        })
    }
}
