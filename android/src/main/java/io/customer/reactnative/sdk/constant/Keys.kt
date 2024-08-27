package io.customer.reactnative.sdk.constant

internal object Keys {
    object Config {
        const val REGION = "region"
        const val AUTO_TRACK_DEVICE_ATTRIBUTES = "autoTrackDeviceAttributes"
        const val CDP_API_KEY = "cdpApiKey"
        const val MIGRATION_SITE_ID = "migrationSiteId"

        const val TRACK_APP_LIFECYCLE_EVENTS = "trackApplicationLifecycleEvents"
        const val FLUSH_AT = "flushAt"
        const val FLUSH_INTERVAL = "flushInterval"
        const val PUSH_CLICK_BEHAVIOR = "pushClickBehaviorAndroid"
    }

    // TODO: Remove PackageConfig later if not in use
    // Keeping it as is right now in case we might need it for user_agent changes
    object PackageConfig {
        const val SOURCE_SDK = "source"
        const val SOURCE_SDK_VERSION = "version"
        const val SOURCE_SDK_VERSION_COMPAT = "sdkVersion"
    }
}
