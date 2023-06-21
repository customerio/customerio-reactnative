import Foundation
import CioInternalCommon
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
    
    private func trackPushMetrics(payload: NSDictionary, event : Metric) {
        guard let deliveryId = payload["CIO-Delivery-ID"] as? String, let deviceToken = payload["CIO-Delivery-Token"] as? String else
        {return}
        
        MessagingPush.shared.trackMetric(deliveryID: deliveryId, event: event, deviceToken: deviceToken)
    }
}
