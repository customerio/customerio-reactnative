import Foundation
import CioMessagingPushFCM
import CioDataPipelines
import FirebaseMessaging

@objc
public class MyAppPushNotificationsHandler : NSObject {

  public override init() {}

  @objc(setupCustomerIOClickHandling)
  public func setupCustomerIOClickHandling() {
    // Initialize MessagingPushFCM module to
    // automatically handle your app’s push notifications that originate from Customer.io
    MessagingPushFCM.initialize(withConfig: MessagingPushConfigBuilder().build())
  }

  // Register device on receiving a device token (FCM)
  @objc(didReceiveRegistrationToken:fcmToken:)
  public func didReceiveRegistrationToken(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
    MessagingPush.shared.messaging(messaging, didReceiveRegistrationToken: fcmToken)
  }
}
