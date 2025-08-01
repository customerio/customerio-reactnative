import CioInternalCommon
import CioMessagingPush
import Foundation

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
