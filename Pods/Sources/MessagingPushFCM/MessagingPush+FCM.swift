import CioMessagingPush
import CioTracking
import Foundation
#if canImport(UserNotifications)
import UserNotifications
#endif

/**
 Convenient extensions so singleton instances of `MessagingPush` can access functions from `MessagingPushFCM`.
 */
extension MessagingPush: MessagingPushFCMInstance {
    public func registerDeviceToken(fcmToken: String?) {
        MessagingPushFCM.shared.registerDeviceToken(fcmToken: fcmToken)
    }

    public func messaging(
        _ messaging: Any,
        didReceiveRegistrationToken fcmToken: String?
    ) {
        MessagingPushFCM.shared.messaging(messaging, didReceiveRegistrationToken: fcmToken)
    }

    public func application(
        _ application: Any,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        MessagingPushFCM.shared.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
    }

    #if canImport(UserNotifications)
    @discardableResult
    public func didReceive(
        _ request: UNNotificationRequest,
        withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void
    ) -> Bool {
        MessagingPushFCM.shared.didReceive(request, withContentHandler: contentHandler)
    }

    public func serviceExtensionTimeWillExpire() {
        MessagingPushFCM.shared.serviceExtensionTimeWillExpire()
    }
    #endif
}
