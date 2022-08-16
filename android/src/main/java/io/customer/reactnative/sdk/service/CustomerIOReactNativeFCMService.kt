package io.customer.reactnative.sdk.service

import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage
import io.customer.messagingpush.CustomerIOFirebaseMessagingService
import io.customer.reactnative.sdk.CustomerIOReactNativeInstance

class CustomerIOReactNativeFCMService : FirebaseMessagingService() {
    override fun onMessageReceived(message: RemoteMessage) {
        CustomerIOFirebaseMessagingService.onMessageReceived(message)
    }

    override fun onNewToken(token: String) {
        with(CustomerIOReactNativeInstance) {
            cachedFCMToken = token
            awaitSDKInitializationWithTimeout {
                setFCMTokenRegistered()
                CustomerIOFirebaseMessagingService.onNewToken(token)
            }
        }
    }
}
