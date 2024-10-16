import Foundation
import UserNotifications
import CioMessagingPushAPN

@objc
public class NotificationServicePushHandler : NSObject {

    public override init() {}

    @objc(didReceive:withContentHandler:)
    public func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {

      MessagingPushAPN.initializeForExtension(
            withConfig: MessagingPushConfigBuilder(cdpApiKey: Env.cdpApiKey)
                  .logLevel(.debug)
                  .build()
          )
      MessagingPush.shared.didReceive(request, withContentHandler: contentHandler)
    }

    @objc(serviceExtensionTimeWillExpire)
    public func serviceExtensionTimeWillExpire() {
        MessagingPush.shared.serviceExtensionTimeWillExpire()
    }
}
