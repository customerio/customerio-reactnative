import CioInternalCommon
@_spi(Internal) import CioMessagingPush
import Foundation
import UIKit

enum PushPermissionStatus: String, CaseIterable {
    case denied
    case notDetermined
    case granted

    var value: String {
        rawValue.uppercased()
    }
}

@objc(NativeMessagingPush)
public class NativeMessagingPush: NSObject {
    private let logger: CioInternalCommon.Logger = DIGraphShared.shared.logger
    private weak var objcEventEmitter: AnyObject?

    /// Lets `CioAppDelegateWrapper` hand Customer.io silent pushes to JavaScript, after the native SDK
    /// records Delivered. Called at process start from NativeMessagingPush.mm, before iOS can deliver
    /// a push that launched the app. Other pushes, and every push in apps whose JavaScript never set a
    /// handler, go to the app delegate as before.
    @available(iOSApplicationExtension, unavailable)
    @objc
    public static func installWrapperBackgroundPushHandler() {
        MessagingPush.wrapperBackgroundPushHandler = { push, completion in
            guard CustomerIOReactNativeBackgroundPushRouter.isHandlerExpected else { return false }
            CustomerIOReactNativeBackgroundPushRouter.accept(push, completion: completion)
            return true
        }
    }

    /// For an app delegate that isn't wrapped with `CioAppDelegateWrapper`: call it first in
    /// `application(_:didReceiveRemoteNotification:fetchCompletionHandler:)`. Returns `true` for a
    /// Customer.io silent push, and then calls `completionHandler` itself; returns `false` for any
    /// other push and leaves `completionHandler` to the caller.
    @available(iOSApplicationExtension, unavailable)
    @objc(handleBackgroundPushWithUserInfo:completionHandler:)
    public static func handleBackgroundPush(
        userInfo: [AnyHashable: Any],
        completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) -> Bool {
        switch MessagingPush.shared.handleBackgroundPush(userInfo: userInfo) {
        case .notBackground:
            return false
        case .unsupported:
            completionHandler(.noData)
            return true
        case .received(let push):
            CustomerIOReactNativeBackgroundPushRouter.accept(push, completion: completionHandler)
            return true
        }
    }

    @objc
    public func setEventEmitter(_ emitter: AnyObject) {
        objcEventEmitter = emitter
    }

    @objc
    func registerBackgroundPushHandler() {
        DispatchQueue.main.async { CustomerIOReactNativeBackgroundPushRouter.register(self) }
    }

    @objc
    func unregisterBackgroundPushHandler() {
        DispatchQueue.main.async { CustomerIOReactNativeBackgroundPushRouter.unregister(self) }
    }

    @objc
    func acknowledgeBackgroundPush(_ id: String) {
        DispatchQueue.main.async { CustomerIOReactNativeBackgroundPushRouter.acknowledge(id) }
    }

    @objc
    func invalidate() {
        DispatchQueue.main.async { CustomerIOReactNativeBackgroundPushRouter.release(self) }
    }

    func emitBackgroundPush(_ body: [String: Any]) {
        // Codegen derives this selector from `onBackgroundPushReceived` in NativeCustomerIOMessagingPush.ts.
        let selector = Selector(("emitOnBackgroundPushReceived:"))
        guard let emitter = objcEventEmitter, emitter.responds(to: selector) else {
            assertionFailure("ObjC event emitter does not respond to selector: emitOnBackgroundPushReceived:")
            return
        }
        _ = emitter.perform(selector, with: body as NSDictionary)
    }

    @objc
    public func onMessageReceived(
        _ message: NSDictionary,
        handleNotificationTrigger: Bool,
        resolve: @escaping RCTPromiseResolveBlock,
        reject: @escaping RCTPromiseRejectBlock
    ) {
        Preconditions.unsupportedOnIOS(methodName: "onMessageReceived")
    }

    // Tracks `opened` push metrics when a push notification is interacted with.
    @objc
    public func trackNotificationResponseReceived(_ payload: NSDictionary) {
        trackPushMetrics(payload: payload, event: .opened)
    }

    // Tracks `delivered` push metrics when a push notification is received.
    @objc
    public func trackNotificationReceived(_ payload: NSDictionary) {
        trackPushMetrics(payload: payload, event: .delivered)
    }

    // Get the currently registered device token for the app
    @objc(getRegisteredDeviceToken:reject:)
    public func getRegisteredDeviceToken(resolve: @escaping (RCTPromiseResolveBlock), reject: @escaping (RCTPromiseRejectBlock)) {
        guard let token = CustomerIO.shared.registeredDeviceToken else {
            reject(CustomerioConstants.cioTag, CustomerioConstants.showDeviceTokenFailureError, nil)
            return
        }
        resolve(token)
    }

    private func trackPushMetrics(payload: NSDictionary, event: Metric) {
        guard let deliveryId = payload[CustomerioConstants.CioDeliveryId] as? String,
              let deviceToken = payload[CustomerioConstants.CioDeliveryToken] as? String
        else { return }

        MessagingPush.shared.trackMetric(deliveryID: deliveryId, event: event, deviceToken: deviceToken)
    }

    @objc(showPromptForPushNotifications:resolve:reject:)
    public func showPromptForPushNotifications(options: [String: AnyHashable], resolve: @escaping (RCTPromiseResolveBlock), reject: @escaping (RCTPromiseRejectBlock)) {
        // Show prompt if status is not determined
        getPushNotificationPermissionStatus { status in
            if status == .notDetermined {
                self.requestPushAuthorization(options: options) { permissionStatus in
                    guard let isGranted = permissionStatus as? Bool else {
                        reject(CustomerioConstants.cioTag, CustomerioConstants.showPromptFailureError, permissionStatus as? Error)
                        return
                    }
                    resolve(isGranted ? PushPermissionStatus.granted.value : PushPermissionStatus.denied.value)
                }
            } else {
                resolve(status.value)
            }
        }
    }

    @objc(getPushPermissionStatus:reject:)
    public func getPushPermissionStatus(resolve: @escaping (RCTPromiseResolveBlock), _: @escaping (RCTPromiseRejectBlock)) {
        getPushNotificationPermissionStatus { status in
            resolve(status.value)
        }
    }

    private func requestPushAuthorization(options: [String: Any], onComplete: @escaping (Any) -> Void) {
        let current = UNUserNotificationCenter.current()
        var notificationOptions: UNAuthorizationOptions = [.alert]
        if let ios = options[CustomerioConstants.platformiOS] as? [String: Any] {
            if let soundOption = ios[CustomerioConstants.sound] as? Bool, soundOption {
                notificationOptions.insert(.sound)
            }
            if let badgeOption = ios[CustomerioConstants.badge] as? Bool, badgeOption {
                notificationOptions.insert(.badge)
            }
        }
        current.requestAuthorization(options: notificationOptions) { isGranted, error in
            if let error = error {
                onComplete(error)
                return
            }
            onComplete(isGranted)
        }
    }

    private func getPushNotificationPermissionStatus(completionHandler: @escaping (PushPermissionStatus) -> Void) {
        var status = PushPermissionStatus.notDetermined
        let current = UNUserNotificationCenter.current()
        current.getNotificationSettings(completionHandler: { permission in
            switch permission.authorizationStatus {
            case .authorized, .provisional, .ephemeral:
                status = .granted
            case .denied:
                status = .denied
            default:
                status = .notDetermined
            }
            completionHandler(status)
        })
    }
}
