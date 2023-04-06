import Foundation
import CioMessagingPushFCM
import UserNotifications
import UIKit
import FirebaseMessaging
// This class manages all function calls to CustomerIO SDK.
@objc
public class MyAppPushNotificationsHandler : NSObject {

  public override init() {}

  // Skip this function if you don't want to request push permissions on launch
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

  @objc(application:deviceToken:)
  public func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
//    MessagingPush.shared.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }

  @objc(application:error:)
  public func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
//    MessagingPush.shared.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
  }

//  @objc(userNotificationCenter:didReceiveNotificationResponse:withCompletionHandler:)
//  public func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
////    let handled = MessagingPush.shared.userNotificationCenter(center, didReceive: response,
////  withCompletionHandler: completionHandler)
////
////    // If the Customer.io SDK does not handle the push, it's up to you to handle it and call the
////    // completion handler. If the SDK did handle it, it called the completion handler for you.
////    if !handled {
////      completionHandler()
////    }
//  }
  
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
