import UserNotifications
import CioMessagingPushFCM
import CioTracking

class NotificationService: UNNotificationServiceExtension {

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
      // Configure SDK options as needed
      CustomerIO.initialize(siteId: Env.siteId, apiKey: Env.apiKey, region: .US) { config in
        config.autoTrackPushEvents = true
        config.logLevel = .debug
      }
      
      MessagingPush.shared.didReceive(request, withContentHandler: contentHandler)
    }
    
    override func serviceExtensionTimeWillExpire() {
      MessagingPush.shared.serviceExtensionTimeWillExpire()
    }
}
