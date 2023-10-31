import CioMessagingPush
import CioTracking
import Foundation
#if canImport(UserNotifications)
import UserNotifications
#endif

/**
 Convenient extensions so singleton instances of `MessagingPush` can access functions from `MessagingPushAPN`.
  */
extension MessagingPush: MessagingPushAPNInstance {
    public func registerDeviceToken(apnDeviceToken: Data) {
        MessagingPushAPN.shared.registerDeviceToken(apnDeviceToken: apnDeviceToken)
    }

    public func application(
        _ application: Any,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        MessagingPushAPN.shared.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
    }

    public func application(
        _ application: Any,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        MessagingPushAPN.shared.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
    }

    #if canImport(UserNotifications)
    @discardableResult
    public func didReceive(
        _ request: UNNotificationRequest,
        withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void
    ) -> Bool {
        MessagingPushAPN.shared.didReceive(request, withContentHandler: contentHandler)
    }

    public func serviceExtensionTimeWillExpire() {
        MessagingPushAPN.shared.serviceExtensionTimeWillExpire()
    }
    #endif
}
