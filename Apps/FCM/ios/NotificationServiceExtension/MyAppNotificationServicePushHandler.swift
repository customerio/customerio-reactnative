import CioMessagingPushFCM
import CioTracking
import Foundation
import UserNotifications

@objc
public class MyAppNotificationServicePushHandler: NSObject {

  public override init() {}

  @objc(didReceive:withContentHandler:)
  public func didReceive(
    _ request: UNNotificationRequest,
    withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void
  ) {
    CustomerIO.initialize(siteId: Env.siteId, apiKey: Env.apiKey, region: .US) { config in
      config.autoTrackDeviceAttributes = true
      config.logLevel = .debug
    }
    MessagingPush.shared.didReceive(request, withContentHandler: contentHandler)
  }

  @objc(serviceExtensionTimeWillExpire)
  public func serviceExtensionTimeWillExpire() {
    MessagingPush.shared.serviceExtensionTimeWillExpire()
  }
}
