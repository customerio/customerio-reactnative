  // Keep the import for your push provider—FCM or APN, and
    // remove the other import statement

  import UserNotifications
  #if canImport(CioMessagingPushAPN)
  import CioMessagingPushAPN
  typealias PushInitializer = MessagingPushAPN
  #else
  import CioMessagingPushFCM
  typealias PushInitializer = MessagingPushFCM
  #endif


  class NotificationService: UNNotificationServiceExtension {
    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {

      // Replace CDP_API_KEY with your actual CDP_API_KEY
      let CDP_API_KEY = ""
      PushInitializer.initializeForExtension(
        withConfig: MessagingPushConfigBuilder(cdpApiKey: CDP_API_KEY)
          .build()
      )

      MessagingPush.shared.didReceive(request, withContentHandler: contentHandler)
    }

    override func serviceExtensionTimeWillExpire() {
      MessagingPush.shared.serviceExtensionTimeWillExpire()
    }
  }
