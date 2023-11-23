package io.customer.messaginginapp.type

import io.customer.messaginginapp.gist.data.model.GistMessageProperties
import io.customer.messaginginapp.gist.data.model.Message

data class InAppMessage(
    val messageId: String,
    val deliveryId: String? // (Currently taken from Gist's campaignId property). Can be null when sending test in-app messages
) {
    companion object {
        internal fun getFromGistMessage(gistMessage: Message): InAppMessage {
            val gistProperties = GistMessageProperties.getGistProperties(gistMessage)
            val campaignId = gistProperties.campaignId

            return InAppMessage(
                messageId = gistMessage.messageId,
                deliveryId = campaignId
            )
        }
    }
}

fun InAppMessage.getMessage(): Message = Message(
    messageId = this.messageId,
    properties = mapOf(
        Pair(
            "gist",
            mapOf(
                Pair("campaignId", this.deliveryId)
            )
        )
    )
)
