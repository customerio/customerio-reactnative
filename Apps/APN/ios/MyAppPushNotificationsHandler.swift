import Foundation
import CioMessagingPushAPN
import CioTracking

/**
 * This file was created based on the Customer.io React Native SDK documentation for setting up push notifications in your app. 
 * 
 * See the documentation to learn how to add this file to your app: 
 * https://customer.io/docs/sdk/react-native/push-notifications/push/#integrate-push-capabilities-in-your-app
 */

@objc
public class MyAppPushNotificationsHandler : NSObject {

  public override init() {}

  @objc(setupCustomerIOClickHandling)
  public func setupCustomerIOClickHandling() {
    // This line of code is required in order for the Customer.io SDK to handle push notification click events.
    // We are working on removing this requirement in a future release.
    // Remember to modify the siteId and apiKey with your own values.
    CustomerIO.initialize(siteId: Env.siteId, apiKey: Env.apiKey, region: .US) { config in
      config.autoTrackDeviceAttributes = true
      config.logLevel = .debug
    }
    MessagingPushAPN.initialize(configOptions: nil)
  }
}
