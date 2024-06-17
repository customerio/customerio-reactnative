import Foundation
import CioMessagingPushAPN

@objc
public class CioMessagingPush : NSObject {

  public override init() {
    super.init()
  }

  @objc
  public static func setup() {
    MessagingPushAPN.initialize(withConfig: MessagingPushConfigBuilder().build())
  }

  @objc
  public static func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    MessagingPush.shared.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }

  @objc
  public static func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
    MessagingPush.shared.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
  }
}
