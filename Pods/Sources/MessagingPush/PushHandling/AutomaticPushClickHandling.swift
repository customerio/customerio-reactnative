import CioInternalCommon
import Foundation

/**
 Sets up the CIO SDK to automatically handle events related to push notifications such as when a push is clicked or deciding if a push should be shown while app is in foreground.

 This feature is complex and these docs are meant to explain how it works.

 When a push notification is clicked on an iOS device, iOS will notify the iOS app for that notification. iOS does this by:
 1. Getting an instance of `UNUserNotificationCenterDelegate` from `UNUserNotificationCenter.current().delegate`.
 2. Calling `userNotificationCenter(_:didReceive:withCompletionHandler:)` on the delegate.

 This is simple when the CIO SDK is the only SDK in an app that needs to get notified when a push is clicked on for a host app. When a customer has installed multiple SDKs into their app that all want to handle when a push is clicked, that's when this gets complex. That's because iOS has a restriction that only 1 object can be set as the `UNUserNotificationCenter.current().delegate`. The CIO SDK when it's initialized can set itself as this delegate instance, but then another SDK can set itself as the delegate instead so the CIO SDK is then no longer called when a push is clicked.

 To solve this problem, the CIO SDK performs this logic:
 1. The CIO SDK forces itself to always be the only `UNUserNotificationCenter.current().delegate` instance of the host iOS app.

 The SDK does this via swizzling. When `UNUserNotificationCenter.current().delegate` setter gets called, the CIO SDK gets notified that this event happened. When a new delegate gets set, the CIO SDK reverses this action by resetting the CIO SDK `UNUserNotificationCenterDelegate` instance as the delegate.

 Related code for this logic:
 * `iOSPushEventListener` - where swizzling is.
 * `iOSPushEventListener` - is the CIO SDK instance of `UNUserNotificationCenterDelegate`.

 2. When the CIO SDK's instance of `UNUserNotificationCenterDelegate` is called, the SDK forwards that push click event to all other `UNUserNotificationCenterDelegate` instances registered to the app. This allows other SDKs the ability to handle a push click event for pushes not sent by CIO.

 Related code for this logic:
 * `NotificationCenterDelegateProxy` - stores all other `UNUserNotificationCenterDelegate` instances that have been registered with the host app.
 * `iOSPushEventListener` - is what calls the proxy class when a push is clicked that was not sent by CIO.

 The goal of this feature is:
 1. The customer does not need to interact with `UNUserNotificationCenter` themselves to get the CIO SDK to process when a push is clicked. The CIO SDK should be able to set this up itself.
 2. The CIO SDK should be able to stay compatible with other SDKs that also want to handle push click events. A customer should be able to install 2+ push notification SDKs in an app and all of them are able to work, even though iOS only allows 1 `UNUserNotificationCenterDelegate` instance to be set in the app.
 */
@available(iOSApplicationExtension, unavailable)
protocol AutomaticPushClickHandling: AutoMockable {
    func start()
}

@available(iOSApplicationExtension, unavailable)
// sourcery: InjectRegister = "AutomaticPushClickHandling"
class AutomaticPushClickHandlingImpl: AutomaticPushClickHandling {
    private let notificationCenterAdapter: UserNotificationsFrameworkAdapter
    private let logger: Logger

    init(notificationCenterAdapter: UserNotificationsFrameworkAdapter, logger: Logger) {
        self.notificationCenterAdapter = notificationCenterAdapter
        self.logger = logger
    }

    func start() {
        logger.debug("Starting automatic push click handling.")

        notificationCenterAdapter.beginListeningNewNotificationCenterDelegateSet()
    }
}
