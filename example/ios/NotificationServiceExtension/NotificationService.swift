import UserNotifications
#if USE_FIREBASE
import CioMessagingPushFCM
typealias PushInitializer = MessagingPushFCM
#else

import CioMessagingPushAPN
typealias PushInitializer = MessagingPushAPN
#endif


class NotificationService: UNNotificationServiceExtension {
  var contentHandler: ((UNNotificationContent) -> Void)?
  var bestAttemptContent: UNMutableNotificationContent?

  override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {

    // Rename the file NotificationServiceExtension/Env.swift.sample to NotificationServiceExtension/Env.swift
    // and set the CDP_API_KEY value to your CDP API Key
  
    PushInitializer.initializeForExtension(
      withConfig: MessagingPushConfigBuilder(cdpApiKey: Env.CDP_API_KEY)
        .build()
    )

    MessagingPush.shared.didReceive(request, withContentHandler: contentHandler)
  }

  override func serviceExtensionTimeWillExpire() {
    MessagingPush.shared.serviceExtensionTimeWillExpire()
  }
}
