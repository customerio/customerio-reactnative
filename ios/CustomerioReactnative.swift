import Foundation
import CioTracking
import Common
import CioMessagingInApp

@objc(CustomerioReactnative)
class CustomerioReactnative: NSObject {

    @objc static func requiresMainQueueSetup() -> Bool {
        false /// false because our native module's initialization does not require access to UIKit
    }
    
    /**
     Initialize the package before sending any calls to the package
     */
    @objc(initialize:configData:packageConfig:)
    func initialize(env: Dictionary<String, AnyHashable>, configData: Dictionary<String, AnyHashable>, packageConfig: Dictionary<String, AnyHashable>) -> Void {
        
        guard let siteId = env["siteId"] as? String, let apiKey = env["apiKey"] as? String, let region = env["region"] as? String, let organizationId = env["organizationId"] as? String else {
            return
        }
        
        guard let pversion = packageConfig["version"] as? String, let source = packageConfig["source"] as? String else {
            return
        }
        
        var sdkSource = SdkWrapperConfig.Source.reactNative
        if source.lowercased() == "expo" {
            sdkSource = SdkWrapperConfig.Source.expo
        }
        
        CustomerIO.initialize(siteId: siteId, apiKey: apiKey, region: Region.getLocation(from: region)) { config in
            config._sdkWrapperConfig = SdkWrapperConfig(source: sdkSource, version: pversion )
            config.autoTrackDeviceAttributes = configData["autoTrackDeviceAttributes"] as! Bool
            config.logLevel = CioLogLevel.getLogValue(for: configData["logLevel"] as! Int)
            config.autoTrackPushEvents = configData["autoTrackPushEvents"] as! Bool
            config.backgroundQueueMinNumberOfTasks = configData["backgroundQueueMinNumberOfTasks"] as! Int
            config.backgroundQueueSecondsDelay = configData["backgroundQueueSecondsDelay"] as! Seconds
            if let trackingApiUrl = configData["trackingApiUrl"] as? String, !trackingApiUrl.isEmpty {
                config.trackingApiUrl = trackingApiUrl
            }
        }
        if let isEnableInApp = configData["enableInApp"] as? Bool, isEnableInApp {
            initializeInApp()
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
    /**
     To register device token with CustomerIO with respect to a user. If a user is not identified then device
     will not get registered.
     */
    @objc(registerDeviceToken:)
    func registerDeviceToken(token: String) -> Void {
        CustomerIO.shared.registerDeviceToken(token)
    }
    /**
        Initialize in-app using customerio package
     */
    private func initializeInApp() -> Void{
        DispatchQueue.main.async {
            MessagingInApp.shared.initialize(eventListener: self)
        }
    }
}

extension CustomerioReactnative: InAppEventListener {
    private func sendEvent(eventType: String, message: InAppMessage, actionValue: String? = nil, actionName: String? = nil) {
        var body = [
            "eventType": eventType,
            "messageId": message.messageId,
            "deliveryId": message.deliveryId
        ]
        if let actionValue = actionValue {
            body["actionValue"] = actionValue
        }
        if let actionName = actionName {
            body["actionName"] = actionName
        }
        CustomerioInAppMessaging.shared?.sendEvent(
            withName: "InAppEventListener", 
            body: body
        )
    }

    func messageShown(message: InAppMessage) {
        sendEvent(eventType: "messageShown", message: message)
    }

    func messageDismissed(message: InAppMessage) {
        sendEvent(eventType: "messageDismissed", message: message)
    }

    func errorWithMessage(message: InAppMessage) {
        sendEvent(eventType: "errorWithMessage", message: message)
    }

    func messageActionTaken(message: InAppMessage, actionValue: String, actionName: String) {
        sendEvent(eventType: "messageActionTaken", message: message, actionValue: actionValue, actionName: actionName)
    }
}
