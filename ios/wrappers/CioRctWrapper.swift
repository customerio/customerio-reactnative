import CioDataPipelines
import CioMessagingInApp
import CioMessagingPush
import UserNotifications
import React

@objc(CioRctWrapper)
class CioRctWrapper: NSObject {
    
    @objc var moduleRegistry: RCTModuleRegistry!
        
    @objc
    func initialize(_ configJson: AnyObject, logLevel: String) {
        do {
            let rtcConfig = try RCTCioConfig.from(configJson)
            let cioInitConfig = cioInitializeConfig(from: rtcConfig, logLevel: logLevel)
            CustomerIO.initialize(withConfig: cioInitConfig.cdp)
            if let inAppConfig = cioInitConfig.inApp {
                    // In app initializes UIView(s) which would crash if run from non-UI queues
                DispatchQueue.main.async {
                    MessagingInApp.initialize(withConfig: inAppConfig)
                    MessagingInApp.shared.setEventListener(self)
                }
            }
        } catch {
            // TODO: Add log when logger feature is implemented
        }
    }
    
    @objc
    func identify(_ userId: String? = nil, traits: [String: Any]? = nil) {
        let codableTraits = traits?.mapValues { AnyCodable($0) }
        
        if let userId = userId {
            CustomerIO.shared.identify(userId: userId, traits: traits)
        } else if codableTraits != nil {
            CustomerIO.shared.identify(traits: codableTraits!)
        } else {
            // TODO: Add log when logger feature is implemented
        }
    }
    
    @objc
    func clearIdentify() {
        CustomerIO.shared.clearIdentify()
    }
    
    @objc
    func track(_ name: String, properties: [String: Any]?) {
        CustomerIO.shared.track(name: name, properties: properties)
    }
    
    @objc
    func screen(_ title: String, properties: [String: Any]?) {
        CustomerIO.shared.screen(title: title, properties: properties)
        flush()
    }
    
    @objc
    func setProfileAttributes(_ attrs: [String: Any]) {
        CustomerIO.shared.profileAttributes = attrs
    }
    
    @objc
    func setDeviceAttributes(_ attrs: [String: Any]) {
        CustomerIO.shared.deviceAttributes = attrs
    }
}

extension CioRctWrapper: InAppEventListener {
    private func sendEvent(eventType: String, message: InAppMessage, actionValue: String? = nil, actionName: String? = nil) {
        var body = [
            CustomerioConstants.eventType: eventType,
            CustomerioConstants.messageId: message.messageId,
            CustomerioConstants.deliveryId: message.deliveryId
        ]
        if let actionValue = actionValue {
            body[CustomerioConstants.actionValue] = actionValue
        }
        if let actionName = actionName {
            body[CustomerioConstants.actionName] = actionName
        }
        // TODO: Add when inapp feature is implemented
        /*
         CustomerioInAppMessaging.shared?.sendEvent(
            withName: CustomerioConstants.inAppEventListener,
            body: body
        )
        */
    }
    
    func messageShown(message: InAppMessage) {
        sendEvent(eventType: CustomerioConstants.messageShown, message: message)
    }
    
    func messageDismissed(message: InAppMessage) {
        sendEvent(eventType: CustomerioConstants.messageDismissed, message: message)
    }
    
    func errorWithMessage(message: InAppMessage) {
        sendEvent(eventType: CustomerioConstants.errorWithMessage, message: message)
    }
    
    func messageActionTaken(message: InAppMessage, actionValue: String, actionName: String) {
        sendEvent(eventType: CustomerioConstants.messageActionTaken, message: message, actionValue: actionValue, actionName: actionName)
    }
}
