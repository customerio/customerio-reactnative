package io.customer.reactnative.sdk.constant

internal object Keys {
    object Environment {
        const val SITE_ID = "siteId"
        const val API_KEY = "apiKey"
        const val REGION = "region"
    }

    object Config {
        const val ENABLE_IN_APP = "enableInApp"
        const val TRACKING_API_URL = "trackingApiUrl"
        const val AUTO_TRACK_DEVICE_ATTRIBUTES = "autoTrackDeviceAttributes"
        const val LOG_LEVEL = "logLevel"
        const val AUTO_TRACK_PUSH_EVENTS = "autoTrackPushEvents"
        const val BACKGROUND_QUEUE_MIN_NUMBER_OF_TASKS = "backgroundQueueMinNumberOfTasks"
        const val BACKGROUND_QUEUE_SECONDS_DELAY = "backgroundQueueSecondsDelay"
    }

    object PackageConfig {
        const val SOURCE_SDK = "source"
        const val SOURCE_SDK_VERSION = "version"
        const val SOURCE_SDK_VERSION_COMPAT = "sdkVersion"
    }
}
