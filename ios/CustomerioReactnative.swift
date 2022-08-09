import Foundation
import CioTracking
import Common

@objc(CustomerioReactnative)
class CustomerioReactnative: NSObject {

    @objc static func requiresMainQueueSetup() -> Bool {
        false /// false because our native module's initialization does not require access to UIKit
    }
    
    /**
     Initialize the package before sending any calls to the package
     */
    @objc(initialize:apiKey:region:configData:pversion:)
    func initialize(siteId: String, apiKey: String, region :String, configData: Dictionary<String, AnyHashable>, pversion: String) -> Void {
        
        CustomerIO.initialize(siteId: siteId, apiKey: apiKey, region: Region.getLocation(from: region)) { config in
            config._sdkWrapperConfig = SdkWrapperConfig(source: SdkWrapperConfig.Source.reactNative, version: pversion )
            config.autoTrackDeviceAttributes = configData["autoTrackDeviceAttributes"] as! Bool
            config.logLevel = CioLogLevel.getLogValue(for: configData["logLevel"] as! Int)
            config.autoTrackPushEvents = configData["autoTrackPushEvents"] as! Bool
            config.backgroundQueueMinNumberOfTasks = configData["backgroundQueueMinNumberOfTasks"] as! Int
            config.backgroundQueueSecondsDelay = configData["backgroundQueueSecondsDelay"] as! Seconds
            if let trackingApiUrl = configData["trackingApiUrl"] as? String, !trackingApiUrl.isEmpty {
                config.trackingApiUrl = trackingApiUrl
            }
        }
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
    
    
    /**
    Track user events with optional data
     */
    @objc(track:data:)
    func track(name : String, data : Dictionary<String, AnyHashable>?) -> Void {
        guard let body = data else {
            CustomerIO.shared.track(name: name)
            return
        }
        CustomerIO.shared.track(name: name, data: body)
    }
    
    /**
    Set custom device attributes such as app preferences, timezone etc
     */
    @objc(setDeviceAttributes:)
    func setDeviceAttributes(data: Dictionary<String, AnyHashable>) -> Void{
        CustomerIO.shared.deviceAttributes = data
    }
    
    /**
     Set custom profile attributes specific to a user
     */
    @objc(setProfileAttributes:)
    func setProfileAttributes(data: Dictionary<String, AnyHashable>) -> Void{
        CustomerIO.shared.profileAttributes = data
    }
    
    /**
     Track screen events to record the screens a user visits with optional data
     */
    @objc(screen:data:)
    func screen(name : String, data : Dictionary<String, AnyHashable>?) -> Void {
        
        guard let body = data else {
            CustomerIO.shared.screen(name: name)
            return
        }
        CustomerIO.shared.screen(name: name, data: body)
    }
    
    @objc(initializeInApp:)
    func initializeInApp(organizationId: String) -> Void{
        MessagingInApp.shared.initialize(organizationId: organizationId)
    }
}

