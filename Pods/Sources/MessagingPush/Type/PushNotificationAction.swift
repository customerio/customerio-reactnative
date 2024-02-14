import Foundation

// A data type that represents a push notification that was acted upon. Such as a push that was clicked on.
public protocol PushNotificationAction {
    var push: PushNotification { get }
    var didClickOnPush: Bool { get }
}
