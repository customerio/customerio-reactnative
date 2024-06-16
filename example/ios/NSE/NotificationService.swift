  // Keep the import for your push provider—FCM or APN, and
  // remove the other import statement
  import CioMessagingPushAPN
  import UserNotifications

  class NotificationService: UNNotificationServiceExtension {
      var contentHandler: ((UNNotificationContent) -> Void)?
      var bestAttemptContent: UNMutableNotificationContent?

      override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
         
        // CDP_API_KEY const comes from untracked file called
        // UntrackedEnv.Swift
        // To run this project
        // Add this file to the NSE target
        // with the content
        // CDP_API_KEY = "YOUR_CDP_API_KEY"
         MessagingPushAPN.initializeForExtension(
              withConfig: MessagingPushConfigBuilder(cdpApiKey: CDP_API_KEY)
                  .build()
         )

         MessagingPush.shared.didReceive(request, withContentHandler: contentHandler)
      }

      override func serviceExtensionTimeWillExpire() {
          MessagingPush.shared.serviceExtensionTimeWillExpire()
      }
  }
