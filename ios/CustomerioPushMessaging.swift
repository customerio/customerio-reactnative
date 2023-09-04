import Foundation
import CioInternalCommon
import CioTracking
import CioMessagingPush


@objc(CustomerioPushMessaging)
class CustomerioPushMessaging: NSObject {

    @objc static func requiresMainQueueSetup() -> Bool {
        false /// false because our native module's initialization does not require access to UIKit
    }
    
    // Tracks `opened` push metrics when a push notification is interacted with.
    @objc(trackNotificationResponseReceived:)
    func trackNotificationResponseReceived(payload: NSDictionary) {
        trackPushMetrics(payload: payload, event: .opened)
    }
    
    // Tracks `delivered` push metrics when a push notification is received.
    @objc(trackNotificationReceived:)
    func trackNotificationReceived(payload: NSDictionary) {
        
        trackPushMetrics(payload: payload, event: .delivered)
    }
    
    @objc(getRegisteredDeviceToken:rejecter:)
    func getRegisteredDeviceToken(resolver resolve: @escaping(RCTPromiseResolveBlock), rejecter reject: @escaping(RCTPromiseRejectBlock)) -> Void {
        
        //TODO: - Uncomment or Update this once https://github.com/customerio/customerio-ios/pull/378 PR is merged
        /*
         guard let token = CustomerIO.shared.registeredDeviceToken() else {
            reject(CustomerioConstants.cioTag, CustomerioConstants.showDeviceTokenFailureError, "")
        }
        resolve(token)
         */
    }

    private func trackPushMetrics(payload: NSDictionary, event : Metric) {
        guard let deliveryId = payload[CustomerioConstants.CioDeliveryId] as? String, let deviceToken = payload[CustomerioConstants.CioDeliveryToken] as? String else
        {return}
        
        MessagingPush.shared.trackMetric(deliveryID: deliveryId, event: event, deviceToken: deviceToken)
    }
}
