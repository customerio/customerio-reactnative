import Foundation
import CioMessagingPushFCM
import CioDataPipelines
import FirebaseMessaging

@objc
public class MyAppPushNotificationsHandler : NSObject {

  public override init() {}

  @objc(setupCustomerIOClickHandling)
  public func setupCustomerIOClickHandling() {
    // This line of code is required in order for the Customer.io SDK to handle push notification click events.
    // We are working on removing this requirement in a future release.
    // Remember to modify the siteId and apiKey with your own values.
    CustomerIO.initialize(withConfig: SDKConfigBuilder(cdpApiKey: Env.apiKey).build())
    MessagingPushFCM.initialize(withConfig: MessagingPushConfigBuilder().build())
  }

  // Register device on receiving a device token (FCM)
  @objc(didReceiveRegistrationToken:fcmToken:)
  public func didReceiveRegistrationToken(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
    MessagingPush.shared.messaging(messaging, didReceiveRegistrationToken: fcmToken)
  }
}
