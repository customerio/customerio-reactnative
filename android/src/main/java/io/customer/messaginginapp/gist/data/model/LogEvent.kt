package io.customer.messaginginapp.gist.data.model

data class LogEvent(
    val name: String,
    val route: String,
    val instanceId: String,
    val queueId: String?,
    val campaignId: String?,
    val platform: String = "android"
)
