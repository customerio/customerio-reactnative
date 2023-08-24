import Foundation
import CioMessagingPushAPN
import UserNotifications
import CioTracking

@objc
public class MyAppPushNotificationsHandler : NSObject {

  public override init() {}

  @objc(setupCustomerIOClickHandling:)
  public func setupCustomerIOClickHandling(withNotificationDelegate notificationDelegate: UNUserNotificationCenterDelegate) {
    // This line of code is required in order for the Customer.io SDK to handle push notification click events.
    // We are working on removing this requirement in a future release.
    // Remember to modify the siteId and apiKey with your own values.
    CustomerIO.initialize(siteId: Env.siteId, apiKey: Env.apiKey, region: .US) { config in
      config.autoTrackDeviceAttributes = true
      config.logLevel = .debug
    }
    
    let center  = UNUserNotificationCenter.current()
    center.delegate = notificationDelegate
  }

  @objc(application:deviceToken:)
  public func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    MessagingPush.shared.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }

  @objc(application:error:)
  public func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
    MessagingPush.shared.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
  }

  @objc(userNotificationCenter:didReceiveNotificationResponse:withCompletionHandler:)
  public func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
    let handled = MessagingPush.shared.userNotificationCenter(center, didReceive: response,
  withCompletionHandler: completionHandler)

    // If the Customer.io SDK does not handle the push, it's up to you to handle it and call the
    // completion handler. If the SDK did handle it, it called the completion handler for you.
    if !handled {
      completionHandler()
    }
  }
}
