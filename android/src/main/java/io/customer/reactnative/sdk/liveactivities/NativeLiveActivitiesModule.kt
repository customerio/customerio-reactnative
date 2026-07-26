package io.customer.reactnative.sdk.liveactivities

import android.graphics.Color
import com.facebook.react.bridge.Promise
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReadableMap
import com.facebook.react.module.annotations.ReactModule
import io.customer.messagingpush.MessagingPushModuleConfig
import io.customer.messagingpush.ModuleMessagingPushFCM
import io.customer.messagingpush.data.communication.CustomerIOLiveNotificationsCallback
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
    private fun getPushModule(): ModuleMessagingPushFCM? = runCatching {
        SDKComponent.modules[PUSH_FCM_MODULE_NAME] as? ModuleMessagingPushFCM
    }.onFailure {
        logger.error("Live Notifications: push module is not initialized. Ensure the SDK is initialized with live activity templates enabled.")
    }.getOrNull()

    override fun start(payload: ReadableMap?, promise: Promise?) {
        val module = getPushModule() ?: return promise.rejectNotAvailable()
        try {
            val data = parseData(requireNotNull(payload) { "payload is required" })
            promise?.resolve(module.startLiveNotification(data))
        } catch (ex: Throwable) {
            promise?.reject("live_activity_start_failed", ex.message, ex)
        }
    }

    override fun update(activityId: String?, payload: ReadableMap?, promise: Promise?) {
        val module = getPushModule() ?: return promise.rejectNotAvailable()
        try {
            val id = requireNotNull(activityId) { "activityId is required" }
            val data = parseData(requireNotNull(payload) { "payload is required" })
            module.updateLiveNotification(id, data)
            promise?.resolve(null)
        } catch (ex: Throwable) {
            promise?.reject("live_activity_update_failed", ex.message, ex)
        }
    }

    override fun end(activityId: String?, promise: Promise?) {
        val module = getPushModule() ?: return promise.rejectNotAvailable()
        try {
            module.endLiveNotification(requireNotNull(activityId) { "activityId is required" })
            promise?.resolve(null)
        } catch (ex: Throwable) {
            promise?.reject("live_activity_end_failed", ex.message, ex)
        }
    }

    override fun startCustom(
        activityType: String?,
        payload: ReadableMap?,
        promise: Promise?,
    ) {
        val module = getPushModule() ?: return promise.rejectNotAvailable()
        try {
            val type = requireNotNull(activityType) { "activityType is required" }
            val data = payload?.toHashMap() ?: emptyMap<String, Any?>()
            promise?.resolve(module.startLiveNotification(type, data))
        } catch (ex: Throwable) {
            promise?.reject("live_activity_start_custom_failed", ex.message, ex)
        }
    }

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

    companion object {
        const val NAME = "NativeCustomerIOLiveActivities"

        // The SDK's ModuleMessagingPushFCM.MODULE_NAME is `internal`, so we mirror its value here.
        private const val PUSH_FCM_MODULE_NAME = "MessagingPushFCM"

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
         * @param config the `liveActivities` config map from the customer app.
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

            val customTypes = config.getTypedValue<List<*>>("customTypes")
                ?.mapNotNull { it as? String }
                .orEmpty()
            if (customTypes.isNotEmpty()) {
                builder.enableCustomLiveNotificationTypes(*customTypes.toTypedArray())
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
