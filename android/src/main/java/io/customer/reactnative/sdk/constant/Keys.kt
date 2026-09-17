package io.customer.reactnative.sdk.constant

internal object Keys {
    object Config {
        const val LOG_LEVEL = "logLevel"
        const val REGION = "region"
        const val AUTO_TRACK_DEVICE_ATTRIBUTES = "autoTrackDeviceAttributes"
        const val CDP_API_KEY = "cdpApiKey"
        const val SITE_ID = "siteId"
        const val MIGRATION_SITE_ID = "migrationSiteId"
        const val TRACK_APP_LIFECYCLE_EVENTS = "trackApplicationLifecycleEvents"
        const val FLUSH_AT = "flushAt"
        const val FLUSH_INTERVAL = "flushInterval"
        const val SCREEN_VIEW_USE = "screenViewUse"
        const val API_HOST = "apiHost"
        const val CDN_HOST = "cdnHost"
        const val NOTIFICATION_INBOX_ACCESSIBILITY_LABELS = "notificationInboxAccessibilityLabels"
        const val COLOR_SCHEME = "colorScheme"
        // Push messaging
        const val PUSH_CLICK_BEHAVIOR = "pushClickBehavior"
    }

    /**
     * Keys of the `notificationInboxAccessibilityLabels` sub-map.
     *
     * [BELL_WITH_UNREAD_COUNT] carries a template string containing [COUNT_PLACEHOLDER] rather than
     * a callback, because wrapper configuration crosses a bridge that carries data but not
     * functions. The native SDK takes a `(Int) -> String`, so the template is converted to one when
     * the module is configured.
     */
    object InboxAccessibilityLabels {
        const val BELL = "bell"
        const val BELL_WITH_UNREAD_COUNT = "bellWithUnreadCount"
        const val LOADING_INDICATOR = "loadingIndicator"
        const val EMPTY_STATE = "emptyState"
        const val COUNT_PLACEHOLDER = "{count}"
    }
}
