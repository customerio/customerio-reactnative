package io.customer.reactnative.sdk.liveactivities

import android.graphics.Color
import com.facebook.react.bridge.Promise
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReadableMap
import com.facebook.react.module.annotations.ReactModule
import io.customer.messagingpush.MessagingPushModuleConfig
import io.customer.messagingpush.ModuleMessagingPushFCM
import io.customer.messagingpush.data.communication.CustomerIOLiveNotificationsCallback
import io.customer.messagingpush.di.pushModuleConfig
import io.customer.messagingpush.livenotification.LiveNotificationAsset
import io.customer.messagingpush.livenotification.LiveNotificationBranding
import io.customer.messagingpush.livenotification.LiveNotificationData
import io.customer.messagingpush.livenotification.LiveNotificationType
import io.customer.reactnative.sdk.NativeCustomerIOLiveActivitiesSpec
import io.customer.reactnative.sdk.extension.getTypedValue
import io.customer.sdk.core.di.SDKComponent
import io.customer.sdk.core.util.Logger

/**
 * React Native module implementation for Customer.io Live Activities / Live Notifications
 * using TurboModules with new architecture.
 *
 * Live Notifications live on the FCM push module ([ModuleMessagingPushFCM]); this bridge
 * maps the wrapper's template payloads to [LiveNotificationData] and forwards them.
 */
@ReactModule(name = NativeLiveActivitiesModule.NAME)
class NativeLiveActivitiesModule(
    private val reactContext: ReactApplicationContext,
) : NativeCustomerIOLiveActivitiesSpec(reactContext) {
    private val logger: Logger
        get() = SDKComponent.logger

    // Live Notifications are hosted by the FCM push module. Reach it via the module registry
    // (the wrapper can't reference the SDK-internal MODULE_NAME constant, so use the literal).
    //
    // Deliberately not runCatching: `as?` yields null instead of throwing, so a failure branch keyed
    // on a thrown error would never run and the message below would never be logged.
    private fun getPushModule(): ModuleMessagingPushFCM? {
        val module = SDKComponent.modules[PUSH_FCM_MODULE_NAME] as? ModuleMessagingPushFCM
        if (module == null) {
            logger.error("Live Notifications: push module is not initialized. Ensure the SDK is initialized with live activity templates enabled.")
        }
        return module
    }

    override fun handleWidgetUrl(url: String?, promise: Promise?) {
        // Customer.io Live Activity widget URLs are an iOS-only contract. Preserve every Android
        // URL so a shared Expo Router redirectSystemPath implementation cannot suppress routing.
        promise?.resolve(url)
    }

    override fun start(payload: ReadableMap?, promise: Promise?) {
        val module = getPushModule() ?: return promise.rejectNotAvailable()
        try {
            val map = requireNotNull(payload) { "payload is required" }
            // Custom types have no built-in template, so they take the SDK's untyped map path and are
            // rendered by the app's own callback. Built-ins keep the typed path.
            val isCustom = map.getString("type") == CUSTOM_TYPE_DISCRIMINATOR
            val activityType = if (isCustom) {
                requireCustomActivityType()
            } else {
                requireNotNull(map.getString("type")) { "payload.type is required" }
            }
            if (activityType !in enabledActivityTypes()) {
                return promise.rejectNotRegistered(activityType)
            }
            val id = if (isCustom) {
                module.startLiveNotification(activityType, customData(map))
            } else {
                module.startLiveNotification(parseData(map))
            }
            promise?.resolve(id)
        } catch (ex: Throwable) {
            promise?.reject("live_activity_start_failed", ex.message, ex)
        }
    }

    override fun update(activityId: String?, payload: ReadableMap?, promise: Promise?) {
        val module = getPushModule() ?: return promise.rejectNotAvailable()
        try {
            val id = requireNotNull(activityId) { "activityId is required" }
            val map = requireNotNull(payload) { "payload is required" }
            if (map.getString("type") == CUSTOM_TYPE_DISCRIMINATOR) {
                module.updateLiveNotification(id, requireCustomActivityType(), customData(map))
            } else {
                module.updateLiveNotification(id, parseData(map))
            }
            promise?.resolve(null)
        } catch (ex: Throwable) {
            promise?.reject("live_activity_update_failed", ex.message, ex)
        }
    }

    /**
     * Ends a live notification. [payload] is accepted for signature parity with iOS, where a final
     * content-state is what makes ActivityKit render a terminal state; Android renders its own
     * terminal state (the notification simply stops being ongoing), so it is ignored here.
     */
    override fun end(activityId: String?, payload: ReadableMap?, promise: Promise?) {
        val module = getPushModule() ?: return promise.rejectNotAvailable()
        try {
            module.endLiveNotification(requireNotNull(activityId) { "activityId is required" })
            promise?.resolve(null)
        } catch (ex: Throwable) {
            promise?.reject("live_activity_end_failed", ex.message, ex)
        }
    }

    /**
     * The app's own identifier for the custom template. Absent means the app sent a custom payload
     * without configuring `liveNotifications.customType` — say so, rather than starting a
     * notification the allowlist would silently drop.
     */
    /**
     * Identifiers the SDK currently has enabled. Read from the live module config rather than cached
     * at wrapper init: the config can also be built by generated native code that never calls
     * [applyLiveActivitiesConfig] — the Expo config plugin does exactly that — and a cached set would
     * be empty there, rejecting every start.
     */
    private fun enabledActivityTypes(): Set<String> =
        SDKComponent.pushModuleConfig.liveNotificationTypes

    /**
     * The custom identifier, preferring what the wrapper saw and otherwise deriving it from the live
     * config: exactly one custom type is supported, so it is the single enabled identifier that no
     * built-in [LiveNotificationType] claims.
     */
    private fun customActivityTypeOrNull(): String? = customActivityType
        ?: enabledActivityTypes().firstOrNull { identifier ->
            LiveNotificationType.entries.none { it.identifier == identifier }
        }

    private fun requireCustomActivityType(): String = requireNotNull(customActivityTypeOrNull()) {
        "No custom Live Activity type is configured. Set `liveNotifications.customType` in your " +
            "Customer.io SDK config to your own reverse-DNS identifier, and render it from your " +
            "CustomerIOLiveNotificationsCallback."
    }

    /** Flattens the payload's `data` map. Android stringifies every value downstream anyway. */
    private fun customData(payload: ReadableMap): Map<String, Any?> =
        payload.getMap("data")?.toHashMap() ?: emptyMap()

    private fun parseData(payload: ReadableMap): LiveNotificationData {
        return when (val type = payload.getString("type")) {
            LiveNotificationType.SEGMENTS.identifier -> LiveNotificationData.Segments(
                header = payload.requireString("header"),
                status = payload.requireString("status"),
                substatus = payload.optString("substatus"),
                segmentsTotal = payload.requireDouble("segmentsTotal").toInt(),
                segmentsComplete = payload.requireDouble("segmentsComplete").toInt(),
                trailingText = payload.optString("trailingText"),
            )

            LiveNotificationType.COUNTDOWN_TIMER.identifier -> LiveNotificationData.CountdownTimer(
                header = payload.requireString("header"),
                title = payload.requireString("title"),
                statusMessage = payload.optString("statusMessage"),
                endTime = if (payload.hasKey("endTime") && !payload.isNull("endTime")) {
                    payload.getDouble("endTime").toLong()
                } else {
                    null
                },
            )

            // A newer native SDK may know this type even though this wrapper build doesn't.
            // Reject softly (the caller turns this into a rejected promise) rather than crash.
            else -> throw IllegalArgumentException("Unsupported Live Activity template: $type")
        }
    }

    private fun ReadableMap.requireString(key: String): String =
        requireNotNull(if (hasKey(key)) getString(key) else null) { "$key is required" }

    private fun ReadableMap.optString(key: String): String? =
        if (hasKey(key) && !isNull(key)) getString(key) else null

    private fun ReadableMap.requireDouble(key: String): Double {
        require(hasKey(key) && !isNull(key)) { "$key is required" }
        return getDouble(key)
    }

    private fun Promise?.rejectNotAvailable() {
        this?.reject(
            "live_activity_module_unavailable",
            "Live Notifications are unavailable. Enable live activity templates in the SDK config.",
        )
    }

    /** Mirrors iOS's `live_activity_type_not_registered` so the same mistake reads the same way. */
    private fun Promise?.rejectNotRegistered(activityType: String?) {
        this?.reject(
            "live_activity_type_not_registered",
            "Live Activity type '$activityType' is not registered. Add it to " +
                "`liveNotifications.types` in your Customer.io SDK config (or set " +
                "`liveNotifications.customType` for a custom type).",
        )
    }

    companion object {
        const val NAME = "NativeCustomerIOLiveActivities"

        // The SDK's ModuleMessagingPushFCM.MODULE_NAME is `internal`, so we mirror its value here.
        private const val PUSH_FCM_MODULE_NAME = "MessagingPushFCM"

        // Discriminator JavaScript sends for the custom template. Not a wire identifier — the
        // notification is started under the app's own `liveNotifications.customType`.
        private const val CUSTOM_TYPE_DISCRIMINATOR = "custom"

        // The app's own identifier for the custom template, captured from config at SDK init.
        @Volatile
        private var customActivityType: String? = null

        // Host-app callback used to render custom (app-defined) live notifications. The native SDK
        // only accepts it at build time, so the app must register it before the SDK initializes
        // (e.g. in Application.onCreate before React Native starts). Stored statically because the
        // SDK config is applied in applyLiveActivitiesConfig, not on this module instance.
        @Volatile
        private var liveNotificationCallback: CustomerIOLiveNotificationsCallback? = null

        /**
         * Register the host app's callback for rendering live notifications itself. Custom
         * (app-defined) activity types have no built-in template, so the app must build the
         * [android.app.Notification] in
         * [CustomerIOLiveNotificationsCallback.createLiveNotification]; returning `null` there
         * falls back to the SDK's built-in template.
         * Call this before the Customer.io SDK is initialized.
         */
        @JvmStatic
        fun setLiveNotificationCallback(callback: CustomerIOLiveNotificationsCallback) {
            liveNotificationCallback = callback
        }

        /**
         * Applies live activity configuration onto the FCM push module's config builder. Live
         * Notifications are hosted by [ModuleMessagingPushFCM], so their config (enabled templates,
         * custom types, branding) is set on the same [MessagingPushModuleConfig].
         *
         * @param builder the push module's config builder.
         * @param config the `liveNotifications` config map from the customer app.
         */
        internal fun applyLiveActivitiesConfig(
            builder: MessagingPushModuleConfig.Builder,
            config: Map<String, Any>,
        ) {
            // Wire the host app's live-notification renderer, if one was registered.
            liveNotificationCallback?.let { builder.setLiveNotificationCallback(it) }

            // Unrecognized identifiers are ignored: a newer native SDK may ship types this
            // wrapper build doesn't know, and that must never break the ones it does know.
            val templateTypes = config.getTypedValue<List<*>>("types")
                ?.mapNotNull { it as? String }
                ?.mapNotNull { identifier ->
                    LiveNotificationType.entries.firstOrNull { it.identifier == identifier }
                }
                .orEmpty()
            if (templateTypes.isNotEmpty()) {
                builder.enableLiveNotificationTypes(*templateTypes.toTypedArray())
            }

            // The custom template. Allowlisting the identifier is both necessary and sufficient:
            // LiveNotificationHandler drops any push whose activityType isn't in this set, and a type
            // with no built-in template falls through to the host app's render callback.
            //
            // Assigned unconditionally: a re-initialize that drops `customType` must clear it, or
            // `start` would keep minting notifications under an identifier no longer allowlisted —
            // which the handler then discards, leaving the caller with an id and nothing on screen.
            val customType = config.getTypedValue<String>("customType")?.trim()?.takeIf { it.isNotEmpty() }
            customActivityType = customType
            if (customType != null) {
                builder.enableCustomLiveNotificationTypes(customType)
            }

            val branding = config.getTypedValue<Map<String, Any>>("branding")
            if (branding != null) {
                val accentColor = branding.getTypedValue<String>("accentColorHex")
                    ?.let { runCatching { Color.parseColor(it) }.getOrNull() }
                    ?: Color.TRANSPARENT
                // A bundled drawable is preferred over a remote URL: it renders without a network
                // round-trip, so the logo is present on the very first frame.
                val logo = branding.getTypedValue<String>("logoResource")
                    ?.let { name -> drawableResId(name)?.let(LiveNotificationAsset::Drawable) }
                    ?: branding.getTypedValue<String>("logoUrl")
                        ?.let(LiveNotificationAsset::RemoteUrl)
                val smallIcon = branding.getTypedValue<String>("smallIconResource")
                    ?.let { name -> drawableResId(name) }
                builder.setLiveNotificationBranding(
                    LiveNotificationBranding(
                        companyName = branding.getTypedValue<String>("companyName").orEmpty(),
                        accentColor = accentColor,
                        smallIcon = smallIcon,
                        logo = logo,
                    ),
                )
            }
        }

        /**
         * Resolve a bundled drawable by name, or `null` when the host app doesn't ship one under
         * that name — a missing asset must degrade to "no image", never crash rendering.
         */
        private fun drawableResId(name: String): Int? {
            val context = SDKComponent.android().applicationContext
            return context.resources
                .getIdentifier(name, "drawable", context.packageName)
                .takeIf { it != 0 }
        }
    }
}
