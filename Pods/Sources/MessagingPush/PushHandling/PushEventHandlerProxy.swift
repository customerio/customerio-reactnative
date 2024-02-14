import CioInternalCommon
import Foundation

// Forwards requests from our SDK to other push event handlers in the host iOS app, if our SDK does not handle the push event.
@available(iOSApplicationExtension, unavailable)
protocol PushEventHandlerProxy: AutoMockable {
    func addPushEventHandler(_ newHandler: PushEventHandler)

    // When these push event handler functions are called, the request is forwarded to other push handlers.
    func onPushAction(_ pushAction: PushNotificationAction, completionHandler: @escaping () -> Void)
    func shouldDisplayPushAppInForeground(_ push: PushNotification, completionHandler: @escaping (Bool) -> Void)
}

/*
 Because the CIO SDK forces itself to be the app's only push click handler, we want our SDK to still be compatible with other SDKs that also need to handle pushes being clicked.

 This class is a proxy that forwards requests to all other click handlers that have been registered with the app. Including 3rd party SDKs.
 */
@available(iOSApplicationExtension, unavailable)
class PushEventHandlerProxyImpl: PushEventHandlerProxy {
    /*
     # Why is this class not stored in the digraph?

     Similar to why the SDK's `UNUserNotificationCenterDelegate` instance is also not in the digraph. See those comments to learn more.
     */
    public static let shared = PushEventHandlerProxyImpl()

    // Use a map so that we only save 1 instance of a given handler.
    private var nestedDelegates: [String: PushEventHandler] = [:]

    func addPushEventHandler(_ newHandler: PushEventHandler) {
        // this line below seems fragile. If we change the class name, this could break.
        // could digraph inject instance of the SDK's intance before setting singleton?
        let doesDelegateBelongToCio = newHandler is IOSPushEventListener

        guard !doesDelegateBelongToCio else {
            return
        }

        nestedDelegates[String(describing: newHandler)] = newHandler
    }

    func onPushAction(_ pushAction: PushNotificationAction, completionHandler: @escaping () -> Void) {
        // If there are no other click handlers, then call the completion handler. Indicating that the CIO SDK handled it.
        guard !nestedDelegates.isEmpty else {
            completionHandler()
            return
        }

        nestedDelegates.forEach { _, delegate in
            delegate.onPushAction(pushAction, completionHandler: completionHandler)
        }
    }

    func shouldDisplayPushAppInForeground(_ push: PushNotification, completionHandler: @escaping (Bool) -> Void) {
        // If there are no other click handlers, then call the completion handler. Indicating that the CIO SDK handled it.
        guard !nestedDelegates.isEmpty else {
            completionHandler(true)
            return
        }

        nestedDelegates.forEach { _, delegate in
            delegate.shouldDisplayPushAppInForeground(push, completionHandler: completionHandler)
        }
    }
}

// Manually add a getter in the digraph.
// We must use this manual approach instead of auto generated code because the class maintains its own singleton instance outside of the digraph.
// This getter allows convenient access to this dependency via the digraph.
extension DIGraph {
    @available(iOSApplicationExtension, unavailable)
    var pushEventHandlerProxy: PushEventHandlerProxy {
        PushEventHandlerProxyImpl.shared
    }
}
