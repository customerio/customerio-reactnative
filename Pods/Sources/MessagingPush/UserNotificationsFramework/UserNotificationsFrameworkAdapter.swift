import CioInternalCommon
import CioTracking
import Foundation
import UserNotifications

/**
 The iOS framework, `UserNotifications`, is abstracted away from the SDK codebase.

 This file is the connection between our SDK and `UserNotifications`.
 In production, iOS will call functions in this file. Those requests are then forwarded onto the abstracted code in the SDK to perform all of the logic.
 */
@available(iOSApplicationExtension, unavailable)
protocol UserNotificationsFrameworkAdapter {
    // A reference to an instance of UNUserNotificationCenterDelegate that we can provide to iOS in production.
    var delegate: UNUserNotificationCenterDelegate { get }

    func beginListeningNewNotificationCenterDelegateSet()

    // Called when a new `UNUserNotificationCenterDelegate` is set on the host app. Our Swizzling is what calls this function.
    func newNotificationCenterDelegateSet(_ newDelegate: UNUserNotificationCenterDelegate?)
}

/**
 Keep this class small and simple because it is only able to be tested in QA testing. All logic for handling push events should be in the rest of the code base that has automated tests around it.
 */
@available(iOSApplicationExtension, unavailable)
class UserNotificationsFrameworkAdapterImpl: NSObject, UNUserNotificationCenterDelegate, UserNotificationsFrameworkAdapter {
    /*
     # Why is this class not stored in the digraph?

     This class is the SDK's `UNUserNotificationCenterDelegate` instance.  Meaning, the CIO SDK registers this class with the OS in order to
     receive callbacks when push notifications are interacted with.

     It's important that the instance of this class provided to the OS stays in memory so our SDK can receive those OS callbacks.

     In order to promise this class's singleton instance stays in memory, the singleton instance is *not* stored inside of the digraph (like all other singletons in our SDK is).
     */
    static let shared = UserNotificationsFrameworkAdapterImpl()

    // It's important that we use do not keep a strong reference to any dependencies or to the digraph. Otherwise, the SDK would crash if the SDK's digraph gets re-initialized and
    // this class tries to access old instances of dependencies.
    private var pushEventHandler: PushEventHandler? {
        diGraph?.pushEventHandler
    }

    private var userNotificationCenter: UserNotificationCenter? {
        diGraph?.userNotificationCenter
    }

    // Convenient getter of the digraph for dependency getters above.
    private var diGraph: DIGraph? {
        SdkInitializedUtilImpl().postInitializedData?.diGraph
    }

    private var notificationCenterDelegateProxy: PushEventHandlerProxy {
        PushEventHandlerProxyImpl.shared
    }

    var delegate: UNUserNotificationCenterDelegate {
        self
    }

    // MARK: Swizzling to get notified when a new delegate is set on host app.

    // The swizzling is tightly coupled to the UserNotitications framework. So, the swizzling is housed in this file.

    func beginListeningNewNotificationCenterDelegateSet() {
        guard var userNotificationCenter = userNotificationCenter else {
            return
        }

        // Sets up swizzling of `UNUserNotificationCenter.current().delegate` setter to get notified when a new delegate is set on host app.
        swizzle(
            forClass: UNUserNotificationCenter.self,
            original: #selector(setter: UNUserNotificationCenter.delegate),
            new: #selector(UNUserNotificationCenter.cio_swizzled_setDelegate(delegate:))
        )

        // This re-assignment triggers NotifiationCenter.delegate setter that we swizzled. We want to run this logic now in case a delegate is already set before the CIO SDK is initialized.
        userNotificationCenter.currentDelegate = userNotificationCenter.currentDelegate
    }

    func newNotificationCenterDelegateSet(_ newDelegate: UNUserNotificationCenterDelegate?) {
        guard let newDelegate = newDelegate else {
            return
        }

        notificationCenterDelegateProxy.addPushEventHandler(UNUserNotificationCenterDelegateWrapper(delegate: newDelegate))
    }

    // MARK: UNUserNotificationCenterDelegate functions.

    // Functions called by iOS framework, `UserNotifications`. This adapter class simply passes these requests to other code in our SDK where the logic exists.
    // Convert UserNotifications files into abstracted data types that our SDK understands.

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        guard let pushEventHandler = pushEventHandler else {
            return
        }

        pushEventHandler.onPushAction(UNNotificationResponseWrapper(response: response), completionHandler: completionHandler)
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        guard let pushEventHandler = pushEventHandler else {
            return
        }

        pushEventHandler.shouldDisplayPushAppInForeground(UNNotificationWrapper(notification: notification)) { shouldShowPush in
            if shouldShowPush {
                if #available(iOS 14.0, *) {
                    completionHandler([.list, .banner, .badge, .sound])
                } else {
                    completionHandler([.badge, .sound])
                }
            } else {
                completionHandler([])
            }
        }
    }

    // Swizzle method convenient when original and swizzled methods both belong to same class.
    func swizzle(forClass: AnyClass, original: Selector, new: Selector) {
        guard let originalMethod = class_getInstanceMethod(forClass, original) else { return }
        guard let swizzledMethod = class_getInstanceMethod(forClass, new) else { return }

        let didAddMethod = class_addMethod(forClass, original, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod))

        if didAddMethod {
            class_replaceMethod(forClass, new, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod))
        } else {
            method_exchangeImplementations(originalMethod, swizzledMethod)
        }
    }
}

// Manually add a getter in the digraph.
// We must use this manual approach instead of auto generated code because the class maintains its own singleton instance outside of the digraph.
// This getter allows convenient access to this dependency via the digraph.
extension DIGraph {
    @available(iOSApplicationExtension, unavailable)
    var userNotificationsFrameworkAdapter: UserNotificationsFrameworkAdapter {
        UserNotificationsFrameworkAdapterImpl.shared
    }
}

// This is a bit confusing and makes the code a little more complex. However, it's the most reliable way found to get UNUserNotificationCenter.delegate swizzling to work by using an extension.
@available(iOSApplicationExtension, unavailable)
extension UNUserNotificationCenter {
    // Swizzled method that gets called when `UNUserNotificationCenter.current().delegate` setter called.
    @objc dynamic func cio_swizzled_setDelegate(delegate: UNUserNotificationCenterDelegate?) {
        guard let diGraph = SdkInitializedUtilImpl().postInitializedData?.diGraph else {
            // SDK not initialized yet. We hope that this function never gets called because auto push click handling will not work if this function called.

            // Forward request to the original implementation that we swizzled. So that the app finishes setting UNUserNotificationCenter.delegate.
            // We have to provide the original delegate object because the SDK has not yet been initialized.
            cio_swizzled_setDelegate(delegate: delegate)

            return
        }

        diGraph.logger.debug("New UNUserNotificationCenter.delegate set. Delegate class: \(String(describing: delegate))")

        diGraph.userNotificationsFrameworkAdapter.newNotificationCenterDelegateSet(delegate)

        // Forward request to the original implementation that we swizzled. So that the app finishes setting UNUserNotificationCenter.delegate.
        //
        // Instead of providing the given 'delegate', provide CIO SDK's click handler.
        // This will force our SDK to be the 1 push click handler of the app instead of the given 'delegate'.
        cio_swizzled_setDelegate(delegate: diGraph.userNotificationsFrameworkAdapter.delegate)
    }
}
