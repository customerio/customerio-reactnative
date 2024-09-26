import Foundation
import CioInternalCommon
import CioMessagingPush

enum PushPermissionStatus: String, CaseIterable {
    case denied
    case notDetermined
    case granted
    
    var value: String {
        return rawValue.uppercased()
    }
}

@objc(CioRctPushMessaging)
class CioRctPushMessaging: NSObject {

    @objc static func requiresMainQueueSetup() -> Bool {
        false /// false because our native module's initialization does not require access to UIKit
    }
    
    // Tracks `opened` push metrics when a push notification is interacted with.
    @objc
    func trackNotificationResponseReceived(payload: NSDictionary) {
        trackPushMetrics(payload: payload, event: .opened)
    }
    
    // Tracks `delivered` push metrics when a push notification is received.
    @objc
    func trackNotificationReceived(payload: NSDictionary) {
        
        trackPushMetrics(payload: payload, event: .delivered)
    }
   
    // Get the currently registered device token for the app
    @objc(getRegisteredDeviceToken:rejecter:)
    func getRegisteredDeviceToken(resolver resolve: @escaping(RCTPromiseResolveBlock), rejecter reject: @escaping(RCTPromiseRejectBlock)) -> Void {
        
         guard let token = CustomerIO.shared.registeredDeviceToken else {
            reject(CustomerioConstants.cioTag, CustomerioConstants.showDeviceTokenFailureError, nil)
             return
        }
        resolve(token)
    }

    private func trackPushMetrics(payload: NSDictionary, event : Metric) {
        guard let deliveryId = payload[CustomerioConstants.CioDeliveryId] as? String, let deviceToken = payload[CustomerioConstants.CioDeliveryToken] as? String else
        {return}
        
        MessagingPush.shared.trackMetric(deliveryID: deliveryId, event: event, deviceToken: deviceToken)
    }
    
    @objc(showPromptForPushNotifications:resolver:rejecter:)
    func showPromptForPushNotifications(options : Dictionary<String, AnyHashable>, resolver resolve: @escaping(RCTPromiseResolveBlock),  rejecter reject: @escaping(RCTPromiseRejectBlock)) -> Void {
        
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
    
    @objc(getPushPermissionStatus:rejecter:)
    func getPushPermissionStatus(resolver resolve: @escaping(RCTPromiseResolveBlock), rejecter reject: @escaping(RCTPromiseRejectBlock)) -> Void {
        getPushNotificationPermissionStatus { status in
            resolve(status.value)
        }
    }
    
    private func requestPushAuthorization(options: [String: Any], onComplete : @escaping(Any) -> Void
        ) {
            let current = UNUserNotificationCenter.current()
            var notificationOptions : UNAuthorizationOptions = [.alert]
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
        
    private func getPushNotificationPermissionStatus(completionHandler: @escaping(PushPermissionStatus) -> Void) {
        var status = PushPermissionStatus.notDetermined
        let current = UNUserNotificationCenter.current()
        current.getNotificationSettings(completionHandler: { permission in
            switch permission.authorizationStatus  {
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
