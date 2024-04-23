import Foundation
import UserNotifications

/**
 The SDK's code is abstracted away from the iOS `UserNotifications` framework.

 This file contains code that runs in production. Code that makes the `UserNotifications` data types
 conform to all of the SDK's abstracted data types.

 All of these wrappers should be small and simple. Their only job is to convert data types between SDK's abstracted data types and `UserNotifications` data types.
 */

struct UNNotificationResponseWrapper: PushNotificationAction {
    public let response: UNNotificationResponse

    var push: PushNotification {
        UNNotificationWrapper(notification: response.notification)
    }

    var didClickOnPush: Bool {
        response.didClickOnPush
    }

    init(response: UNNotificationResponse) {
        self.response = response
    }
}

public struct UNNotificationWrapper: PushNotification {
    // Important: This class can be used to modify a push or read-only access on a push.
    // Return the modified content, first. If that is nil, then return the original content.
    public var notificationContent: UNNotificationContent {
        mutableNotificationContent ?? notificationRequest.content
    }

    public let notification: UNNotification?
    public let notificationRequest: UNNotificationRequest

    // This mutable copy allows the push content to be modified. This is needed for composing rich push notifications.
    private var mutableNotificationContent: UNMutableNotificationContent?

    public var pushId: String {
        notificationRequest.identifier
    }

    public var deliveryDate: Date? {
        notification?.date
    }

    public var title: String {
        get {
            notificationContent.title
        }
        set {
            mutableNotificationContent?.title = newValue
        }
    }

    public var body: String {
        get {
            notificationContent.body
        }
        set {
            mutableNotificationContent?.body = newValue
        }
    }

    public var data: [AnyHashable: Any] {
        get {
            notificationContent.userInfo
        }
        set {
            mutableNotificationContent?.userInfo = newValue
        }
    }

    public var attachments: [PushAttachment] {
        get {
            notificationContent.attachments.map {
                PushAttachment(identifier: $0.identifier, localFileUrl: $0.url)
            }
        }
        set {
            notificationCenterAttachments = newValue.map { pushAttachment in
                try? UNNotificationAttachment(
                    identifier: pushAttachment.identifier,
                    url: pushAttachment.localFileUrl,
                    options: nil
                )
            }.mapNonNil()
        }
    }

    public var notificationCenterAttachments: [UNNotificationAttachment] {
        get {
            notificationContent.attachments
        }
        set {
            mutableNotificationContent?.attachments = newValue
        }
    }

    init(notification: UNNotification) {
        self.notification = notification
        self.notificationRequest = notification.request

        // We do not expect mutableCopy() to be nil, but it is possible according to the public-API. So we must have it be optional.
        self.mutableNotificationContent = notification.request.content.mutableCopy() as? UNMutableNotificationContent
    }

    init(notificationRequest: UNNotificationRequest) {
        self.notification = nil
        self.notificationRequest = notificationRequest

        // We do not expect mutableCopy() to be nil, but it is possible according to the public-API. So we must have it be optional.
        self.mutableNotificationContent = notificationRequest.content.mutableCopy() as? UNMutableNotificationContent
    }
}

class UNUserNotificationCenterDelegateWrapper: PushEventHandler {
    private let delegate: UNUserNotificationCenterDelegate

    init(delegate: UNUserNotificationCenterDelegate) {
        self.delegate = delegate
    }

    func onPushAction(_ pushAction: PushNotificationAction, completionHandler: @escaping () -> Void) {
        guard let userNotificationsWrapperInstance = pushAction as? UNNotificationResponseWrapper else {
            return
        }

        let delegateGotCalled: Void? = delegate.userNotificationCenter?(UNUserNotificationCenter.current(), didReceive: userNotificationsWrapperInstance.response, withCompletionHandler: completionHandler)

        if delegateGotCalled == nil { // delegate did not implement this optional method. Call the completionHandler for them.
            completionHandler()
        }
    }

    func shouldDisplayPushAppInForeground(_ push: PushNotification, completionHandler: @escaping (Bool) -> Void) {
        guard let unnotification = (push as? UNNotificationWrapper)?.notification else {
            return
        }

        let delegateGotCalled: Void? = delegate.userNotificationCenter?(UNUserNotificationCenter.current(), willPresent: unnotification) { displayPushInForegroundOptions in
            let shouldShowPush = !displayPushInForegroundOptions.isEmpty

            completionHandler(shouldShowPush)
        }

        if delegateGotCalled == nil { // delegate did not implement this optional method. Call the completionHandler for them.
            completionHandler(false)
        }
    }
}
