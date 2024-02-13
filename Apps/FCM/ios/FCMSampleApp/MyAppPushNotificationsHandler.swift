import Foundation
import CioMessagingPushFCM
import FirebaseMessaging
import CioTracking

@objc
public class MyAppPushNotificationsHandler : NSObject {

  public override init() {}

  @objc(setupCustomerIOClickHandling)
  public func setupCustomerIOClickHandling() {
    // This line of code is required in order for the Customer.io SDK to handle push notification click events.
    // We are working on removing this requirement in a future release.
    // Remember to modify the siteId and apiKey with your own values.
    CustomerIO.initialize(siteId: Env.siteId, apiKey: Env.apiKey, region: Region.US) { config in
      config.autoTrackDeviceAttributes = true
      
      // Configuration settings below are convenient for internal Customer.io testing. 
      // They are optional for your setup. 
      config.logLevel = .debug
    }
    MessagingPushFCM.initialize(configOptions: nil)    
  }

  // Register device on receiving a device token (FCM)
  @objc(didReceiveRegistrationToken:fcmToken:)
  public func didReceiveRegistrationToken(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
    MessagingPush.shared.messaging(messaging, didReceiveRegistrationToken: fcmToken)
  }
}
