import UserNotifications

#if USE_FCM
#if canImport(CioMessagingPushFCM)
import CioMessagingPushFCM
typealias PushInitializer = MessagingPushFCM
#endif
#else
#if canImport(CioMessagingPushAPN)
import CioMessagingPushAPN
typealias PushInitializer = MessagingPushAPN
#endif
#endif


class NotificationService: UNNotificationServiceExtension {
  var contentHandler: ((UNNotificationContent) -> Void)?
  var bestAttemptContent: UNMutableNotificationContent?

  override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {

#if canImport(CioMessagingPushFCM) || canImport(CioMessagingPushAPN)
    // Customer.io rich push is included in this build (CIO_ENABLED != 0).
    // Rename the file NotificationServiceExtension/Env.swift.sample to NotificationServiceExtension/Env.swift
    // and set the CDP_API_KEY value to your CDP API Key
    PushInitializer.initializeForExtension(
      withConfig: MessagingPushConfigBuilder(cdpApiKey: Env.CDP_API_KEY)
        .logLevel(.debug)
        .appGroupId("group.io.customer.ami.cio")
        .build()
    )

    MessagingPush.shared.didReceive(request, withContentHandler: contentHandler)
#else
    // Customer.io excluded (CIO_ENABLED=0): no rich-push processing — deliver
    // the notification unmodified so the extension is inert but valid.
    self.contentHandler = contentHandler
    self.bestAttemptContent = request.content.mutableCopy() as? UNMutableNotificationContent
    contentHandler(bestAttemptContent ?? request.content)
#endif
  }

  override func serviceExtensionTimeWillExpire() {
#if canImport(CioMessagingPushFCM) || canImport(CioMessagingPushAPN)
    MessagingPush.shared.serviceExtensionTimeWillExpire()
#else
    if let contentHandler = contentHandler, let bestAttemptContent = bestAttemptContent {
      contentHandler(bestAttemptContent)
    }
#endif
  }
}
