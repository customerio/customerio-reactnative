package io.customer.messaginginapp.gist

interface GistEnvironmentEndpoints {
    fun getGistQueueApiUrl(): String
    fun getEngineApiUrl(): String
    fun getGistRendererUrl(): String
}

enum class GistEnvironment : GistEnvironmentEndpoints {
    DEV {
        override fun getGistQueueApiUrl() = "https://gist-queue-consumer-api.cloud.dev.gist.build"
        override fun getEngineApiUrl() = "https://engine.api.dev.gist.build"
        override fun getGistRendererUrl() = "https://renderer.gist.build/2.0"
    },

    LOCAL {
        override fun getGistQueueApiUrl() = "http://queue.api.local.gist.build:86"
        override fun getEngineApiUrl() = "http://engine.api.local.gist.build:82"
        override fun getGistRendererUrl() = "https://renderer.gist.build/2.0"
    },

    PROD {
        override fun getGistQueueApiUrl() = "https://gist-queue-consumer-api.cloud.gist.build"
        override fun getEngineApiUrl() = "https://engine.api.gist.build"
        override fun getGistRendererUrl() = "https://renderer.gist.build/2.0"
    }
}
