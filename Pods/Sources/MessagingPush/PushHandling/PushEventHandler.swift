import CioInternalCommon
import Foundation

// A protocol that can handle push notification events. Such as when a push is received on the device or when a push is clicked on.
// Note: This is meant to be an abstraction of the iOS `UNUserNotificationCenterDelegate` protocol.
protocol PushEventHandler: AutoMockable {
    // Called when a push notification was acted upon. Either clicked or swiped away.
    //
    // Replacement of: `userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void)`
    func onPushAction(_ pushAction: PushNotificationAction, completionHandler: @escaping () -> Void)
    // Called when a push is received and the app is in the foreground. iOS asks the host app if the push should be shown, or not.
    //
    // Replacement of: `userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void)`
    // `completionHandler`'s `Bool` is `true` if the push should be displayed when app in foreground.
    func shouldDisplayPushAppInForeground(_ push: PushNotification, completionHandler: @escaping (Bool) -> Void)
}
