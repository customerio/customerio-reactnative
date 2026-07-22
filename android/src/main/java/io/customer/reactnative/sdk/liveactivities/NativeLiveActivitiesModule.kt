package io.customer.reactnative.sdk.liveactivities

import android.graphics.Color
import com.facebook.react.bridge.Promise
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReadableMap
import com.facebook.react.module.annotations.ReactModule
import io.customer.messagingpush.MessagingPushModuleConfig
import io.customer.messagingpush.ModuleMessagingPushFCM
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

    override fun handleDeepLinkOpen(url: String?, promise: Promise?) {
        // Deep-link/opened attribution for Live Activities is an iOS-only concept; no-op on Android.
        promise?.resolve(false)
    }

    private fun parseData(payload: ReadableMap): LiveNotificationData {
        return when (val type = payload.getString("type")) {
            "segments" -> LiveNotificationData.Segments(
                header = payload.requireString("header"),
                status = payload.requireString("status"),
                substatus = payload.optString("substatus"),
                segmentsTotal = payload.requireDouble("segmentsTotal").toInt(),
                segmentsComplete = payload.requireDouble("segmentsComplete").toInt(),
                trailingText = payload.optString("trailingText"),
            )

            "countdownTimer" -> LiveNotificationData.CountdownTimer(
                header = payload.requireString("header"),
                title = payload.requireString("title"),
                statusMessage = payload.optString("statusMessage"),
                endTime = if (payload.hasKey("endTime") && !payload.isNull("endTime")) {
                    payload.getDouble("endTime").toLong()
                } else {
                    null
                },
            )

            else -> throw IllegalArgumentException("Unknown live activity template type: $type")
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
            val templateTypes = config.getTypedValue<List<*>>("templates")
                ?.mapNotNull { it as? String }
                ?.mapNotNull { name ->
                    when (name) {
                        "segments" -> LiveNotificationType.SEGMENTS
                        "countdownTimer" -> LiveNotificationType.COUNTDOWN_TIMER
                        else -> null
                    }
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
                val logoUrl = branding.getTypedValue<String>("logoUrl")
                val smallIcon = branding.getTypedValue<String>("smallIconResource")
                    ?.let { name ->
                        val context = SDKComponent.android().applicationContext
                        context.resources
                            .getIdentifier(name, "drawable", context.packageName)
                            .takeIf { it != 0 }
                    }
                builder.setLiveNotificationBranding(
                    LiveNotificationBranding(
                        companyName = branding.getTypedValue<String>("companyName").orEmpty(),
                        accentColor = accentColor,
                        smallIcon = smallIcon,
                        logo = logoUrl?.let { LiveNotificationAsset.RemoteUrl(it) },
                    ),
                )
            }
        }
    }
}
