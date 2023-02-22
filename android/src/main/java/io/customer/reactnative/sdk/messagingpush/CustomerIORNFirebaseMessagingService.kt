package io.customer.reactnative.sdk.messagingpush

import android.annotation.SuppressLint
import io.customer.messagingpush.CustomerIOFirebaseMessagingService

/**
 * Customer.io firebase messaging service class that inherits base messaging service from native
 * Android SDK to get all basic functionality. This class can be used to include react native
 * specific features e.g. triggering events to JS/TS, etc.
 */
@SuppressLint("MissingFirebaseInstanceTokenRefresh")
open class CustomerIORNFirebaseMessagingService : CustomerIOFirebaseMessagingService()
