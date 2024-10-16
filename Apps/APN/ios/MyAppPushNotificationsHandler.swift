import Foundation
import CioMessagingPushAPN

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
    // Initialize MessagingPushAPN module to
    // automatically handle your app’s push notifications that originate from Customer.io
    MessagingPushAPN.initialize(withConfig: MessagingPushConfigBuilder().build())
  }

  @objc(application:deviceToken:)
  public func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    MessagingPush.shared.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }

  @objc(application:error:)
  public func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
    MessagingPush.shared.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
  }
}
