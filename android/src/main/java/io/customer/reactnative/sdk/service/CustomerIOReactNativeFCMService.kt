package io.customer.reactnative.sdk.service

import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage
import io.customer.messagingpush.CustomerIOFirebaseMessagingService
import io.customer.reactnative.sdk.CustomerIOReactNativeInstance

class CustomerIOReactNativeFCMService : FirebaseMessagingService() {
    override fun onMessageReceived(message: RemoteMessage) {
        CustomerIOReactNativeInstance.initializeSDKFromContext(context = applicationContext)
        CustomerIOFirebaseMessagingService.onMessageReceived(message)
    }

    override fun onNewToken(token: String) {
        CustomerIOFirebaseMessagingService.onNewToken(token)
    }
}
