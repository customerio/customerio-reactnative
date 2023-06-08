import Foundation
import CioMessagingPushFCM
import UserNotifications
import FirebaseMessaging
import CioTracking

// This class manages all function calls to CustomerIO SDK.
@objc
public class MyAppPushNotificationsHandler : NSObject {

  public override init() {}

  // Skip this function if you don't want to request push permissions on launch.
     // Use `customerio-reactnative` version `>= 2.2.0` to display the native push permission prompt.
     // See `Prompt users to opt-into push notifications` for more information.
     @objc(registerPushNotification:)
     public func registerPushNotification(withNotificationDelegate notificationDelegate: UNUserNotificationCenterDelegate) {

       let center  = UNUserNotificationCenter.current()
       center.delegate = notificationDelegate
       center.requestAuthorization(options: [.sound, .alert, .badge]) { (granted, error) in
         if error == nil{
           DispatchQueue.main.async {
             UIApplication.shared.registerForRemoteNotifications()
           }
         }
       }
     }

     // Register device on receiving a device token (FCM)
     @objc(didReceiveRegistrationToken:fcmToken:)
     public func didReceiveRegistrationToken(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
       MessagingPush.shared.messaging(messaging, didReceiveRegistrationToken: fcmToken)
     }

     // To capture push metrics
     @objc(userNotificationCenter:response:completionHandler:)
     public func userNotificationCenter(center:UNUserNotificationCenter, didReceive response: UNNotificationResponse, completionHandler: @escaping () -> Void){
       let _ = MessagingPush.shared.userNotificationCenter(center, didReceive: response, withCompletionHandler: completionHandler)
     }

}
