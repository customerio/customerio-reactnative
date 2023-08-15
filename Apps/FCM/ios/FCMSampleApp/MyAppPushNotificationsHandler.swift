import CioMessagingPushFCM
import CioTracking
import FirebaseMessaging
import Foundation

@objc
public class MyAppPushNotificationsHandler: NSObject {

  public override init() {}

  // Register device on receiving a device token (FCM)
  @objc(didReceiveRegistrationToken:fcmToken:)
  public func didReceiveRegistrationToken(
    _ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?
  ) {
    MessagingPush.shared.messaging(messaging, didReceiveRegistrationToken: fcmToken)
  }

  // To capture push metrics
  @objc(userNotificationCenter:response:completionHandler:)
  public func userNotificationCenter(
    center: UNUserNotificationCenter, didReceive response: UNNotificationResponse,
    completionHandler: @escaping () -> Void
  ) {
    let _ = MessagingPush.shared.userNotificationCenter(
      center, didReceive: response, withCompletionHandler: completionHandler)
  }

  @objc(initializeCioSdk)
  public func initializeCioSdk() {
    CustomerIO.initialize(siteId: Env.siteId, apiKey: Env.apiKey, region: .US) {
      config in config.autoTrackDeviceAttributes = true
      config.logLevel = .debug
    }
  }
}
