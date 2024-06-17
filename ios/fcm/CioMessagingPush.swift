import Foundation
import CioMessagingPushFCM
import FirebaseMessaging

@objc
public class CioMessagingPush : NSObject {

  public override init() {
    super.init()
  }

  @objc
  public static func setup() {
    MessagingPushFCM.initialize(withConfig: MessagingPushConfigBuilder().build())
  }

  @objc
  public static func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
    MessagingPush.shared.messaging(messaging, didReceiveRegistrationToken: fcmToken)
  }

  @objc
  public static func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
    MessagingPush.shared.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
  }
}
