import Foundation
import CioTracking

@objc(CustomerioReactnative)
class CustomerioReactnative: NSObject {

    @objc static func requiresMainQueueSetup() -> Bool {
        false /// false because our native module's initialization does not require access to UIKit
    }
    
    /**
     Initialize the package before sending any calls to the package
     */
    @objc(initialize:apiKey:region:)
    func initialize(siteId: String, apiKey: String, region :String) -> Void {
        CustomerIO.initialize(siteId: siteId, apiKey: apiKey, region: Region.getLocation(from: region))
    }
    
    /**
     Identify a customer, note that only one customer is identified at a time

     - Parameters:
     - identifier: unique ID of the customer.
     - body (Optional): attributes of a customer.
     */
    @objc(identify:body:)
    func identify(identifier: String, body: Dictionary<String, AnyHashable>?) -> Void {
    
        guard let data = body else {
            CustomerIO.shared.identify(identifier: identifier)
            return
        }
        CustomerIO.shared.identify(identifier: identifier, body: data)
    }
    
    /**
     To stop identifying the user.
     Once the identity is cleared then the user can not be tracked, hence no events/activities are sent to the workspace
     */
    @objc(clearIdentify)
    func clearIdentify() {
        CustomerIO.shared.clearIdentify()
    }
    
    
    @objc(track:data:)
    func track(name : String, data : Dictionary<String, AnyHashable>?) -> Void {
        guard let body = data else {
            CustomerIO.shared.track(name: name)
            return
        }
        CustomerIO.shared.track(name: name, data: body)
    }
    
    @objc(setDeviceAttributes:)
    func setDeviceAttributes(data: Dictionary<String, AnyHashable>) -> Void{
        CustomerIO.shared.deviceAttributes = data
    }
    
    @objc(config:)
    func config(data : Dictionary<String, AnyHashable>) -> Void{
        if let trackingApiUrl = data["trackingApiUrl"] as? String, !trackingApiUrl.isEmpty {
            CustomerIO.config {
                $0.trackingApiUrl = trackingApiUrl
            }
        }
        CustomerIO.config {
            $0.autoTrackDeviceAttributes = data["autoTrackDeviceAttributes"] as! Bool
            $0.logLevel = CioLogLevel.getLogValue(for: data["logLevel"] as! Int)
            $0.autoTrackPushEvents = data["autoTrackPushEvents"] as! Bool
            $0.backgroundQueueMinNumberOfTasks = data["backgroundQueueMinNumberOfTasks"] as! Int
            $0.backgroundQueueSecondsDelay = data["backgroundQueueSecondsDelay"] as! Seconds
        }
    }
}

