import Foundation
import CioMessagingPushAPN
import CioDataPipelines

@objc
public class APNHandler : NSObject {

  public override init() {}

  @objc(setupCustomerIOClickHandling)
  public static func setupCustomerIOClickHandling() {
    // This line of code is required in order for the Customer.io SDK to handle push notification click events.
    // We are working on removing this requirement in a future release.
    // Remember to modify the siteId, apiKey and region with your own values.
    
    MessagingPushAPN.initialize(withConfig: MessagingPushConfigBuilder().build())
  }

  @objc(application:deviceToken:)
  public static func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    MessagingPush.shared.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }

  @objc(application:error:)
  public static func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
    MessagingPush.shared.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
  }
}
