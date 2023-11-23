package io.customer.messaginginapp.gist.data.repository

import io.customer.messaginginapp.gist.data.model.Message
import retrofit2.Response
import retrofit2.http.Body
import retrofit2.http.POST
import retrofit2.http.Path

interface GistQueueService {
    @POST("/api/v1/users")
    suspend fun fetchMessagesForUser(@Body body: Any = Object()): Response<List<Message>>

    @POST("/api/v1/logs/message/{messageId}")
    suspend fun logMessageView(@Path("messageId") messageId: String)

    @POST("/api/v1/logs/queue/{queueId}")
    suspend fun logUserMessageView(@Path("queueId") queueId: String)
}
