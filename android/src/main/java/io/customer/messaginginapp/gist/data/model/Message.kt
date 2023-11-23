package io.customer.messaginginapp.gist.data.model
import java.util.*

enum class MessagePosition(val position: String) {
    TOP("top"),
    CENTER("center"),
    BOTTOM("bottom")
}

data class GistProperties(
    val routeRule: String?,
    val elementId: String?,
    val campaignId: String?,
    val position: MessagePosition,
    val persistent: Boolean
)

data class Message(
    val messageId: String = "",
    val instanceId: String = UUID.randomUUID().toString(),
    val queueId: String? = null,
    val properties: Map<String, Any?>? = null
)

class GistMessageProperties {
    companion object {
        fun getGistProperties(message: Message): GistProperties {
            var routeRule: String? = null
            var elementId: String? = null
            var campaignId: String? = null
            var position: MessagePosition = MessagePosition.CENTER
            var persistent = false

            message.properties?.let { properties ->
                properties["gist"]?.let { gistProperties ->
                    (gistProperties as Map<String, Any?>).let { gistProperties ->
                        gistProperties["routeRuleAndroid"]?.let { rule ->
                            (rule as String).let { stringRule ->
                                routeRule = stringRule
                            }
                        }
                        gistProperties["campaignId"]?.let { id ->
                            (id as String).let { stringId ->
                                campaignId = stringId
                            }
                        }
                        gistProperties["elementId"]?.let { id ->
                            (id as String).let { stringId ->
                                elementId = stringId
                            }
                        }
                        gistProperties["position"]?.let { messagePosition ->
                            (messagePosition as String).let { stringPosition ->
                                position = MessagePosition.valueOf(stringPosition.uppercase())
                            }
                        }
                        gistProperties["persistent"]?.let { id ->
                            (id as? Boolean)?.let { persistentValue ->
                                persistent = persistentValue
                            }
                        }
                    }
                }
            }
            return GistProperties(routeRule = routeRule, elementId = elementId, campaignId = campaignId, position = position, persistent = persistent)
        }
    }
}
