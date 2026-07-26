package io.customer.rn_sample.fcm

import android.app.Application
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import androidx.core.app.NotificationCompat
import com.facebook.react.PackageList
import com.facebook.react.ReactApplication
import com.facebook.react.ReactHost
import com.facebook.react.ReactNativeApplicationEntryPoint.loadReactNative
import com.facebook.react.defaults.DefaultReactHost.getDefaultReactHost
import io.customer.messagingpush.data.communication.CustomerIOLiveNotificationsCallback
import io.customer.messagingpush.data.model.CustomerIOParsedPushPayload
import io.customer.reactnative.sdk.liveactivities.NativeLiveActivitiesModule

class MainApplication : Application(), ReactApplication {

  override val reactHost: ReactHost by lazy {
    getDefaultReactHost(
      context = applicationContext,
      packageList =
        PackageList(this).packages.apply {
          // Packages that cannot be autolinked yet can be added manually here, for example:
          // add(MyReactNativePackage())
        },
    )
  }

  override fun onCreate() {
    super.onCreate()

    // Register the host-app renderer for custom (app-defined) live notifications BEFORE React
    // Native (and the Customer.io SDK) initialize. Custom activity types have no built-in
    // template, so the SDK asks this callback to build the Notification for them.
    NativeLiveActivitiesModule.setLiveNotificationCallback(RideshareLiveNotificationCallback())

    loadReactNative(this)
  }
}

/**
 * Renders the custom "rideshare" live notification. The SDK calls
 * [createLiveNotification] for every live notification; return a built [Notification] to take
 * over rendering for our custom type, or null to let the SDK use its built-in templates.
 */
private class RideshareLiveNotificationCallback : CustomerIOLiveNotificationsCallback {
  override fun createLiveNotification(
    payload: CustomerIOParsedPushPayload,
    context: Context,
  ): Notification? {
    // Live-notification template fields are flattened into `extras`; the activity type is under
    // the reserved "notification_type" key.
    val extras = payload.extras
    if (extras.getString("notification_type") != RIDESHARE_TYPE) return null

    // The SDK re-invokes this callback on the "end" event. Return a terminal, non-ongoing
    // notification then so it can be dismissed instead of sticking around forever.
    val ended = extras.getString("event") == "end"

    val driverName = extras.getString("driverName") ?: "Your driver"
    val status = extras.getString("status") ?: ""
    // Numeric fields cross the bridge as doubles and are stored as strings ("5.0"); render as int.
    val etaMinutes = extras.getString("etaMinutes")?.toDoubleOrNull()?.toInt()
    val text = buildString {
      append(driverName)
      if (status.isNotEmpty()) append(" • ").append(status)
      if (etaMinutes != null) append(" • ETA ").append(etaMinutes).append(" min")
    }

    ensureChannel(context)
    return NotificationCompat.Builder(context, CHANNEL_ID)
      .setContentTitle(if (ended) "Rideshare complete" else "Rideshare")
      .setContentText(text)
      .setSmallIcon(context.applicationInfo.icon)
      .setOngoing(!ended)
      .setOnlyAlertOnce(true)
      .build()
  }

  private fun ensureChannel(context: Context) {
    val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
    if (manager.getNotificationChannel(CHANNEL_ID) == null) {
      manager.createNotificationChannel(
        NotificationChannel(CHANNEL_ID, "Rideshare", NotificationManager.IMPORTANCE_DEFAULT),
      )
    }
  }

  companion object {
    private const val RIDESHARE_TYPE = "io.customer.livenotifications.custom.rideshare"
    private const val CHANNEL_ID = "rideshare_live"
  }
}
