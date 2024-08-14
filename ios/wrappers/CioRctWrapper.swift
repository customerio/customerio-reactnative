import CioDataPipelines
import CioMessagingInApp
import CioMessagingPush
import UserNotifications
import React

func flush() {
#if DEBUG
    CustomerIO.shared.flush()
#endif
}

@objc(CioRctWrapper)
class CioRctWrapper: NSObject {
    
    @objc var moduleRegistry: RCTModuleRegistry!
    
    private var logger: CioLogger!
    
    @objc
    func initialize(_ configJson: AnyObject, logLevel: String) {
        do {
            logger = CioLoggerWrapper.getInstance(moduleRegistry: moduleRegistry, logLevel: CioLogLevel(rawValue: logLevel) ?? .none)
            
            logger.debug("Initializing CIO with config: \(configJson)")
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
            flush()
        } catch {
            logger.error("Couldn't initialize CustomerIO: \(error)")
        }
    }
    
    @objc
    func identify(_ userId: String? = nil, traits: [String: Any]? = nil) {
        if let userId, let traits {
            CustomerIO.shared.identify(userId: userId, traits: traits)
        } else if let userId {
            CustomerIO.shared.identify(userId: userId, traits: traits)
        } else {
            logger.error("CustomerIO.identify called without an ID or traits")
        }
        flush()
    }
    
    @objc
    func clearIdentify() {
        CustomerIO.shared.clearIdentify()
        flush()
    }
    
    @objc
    func track(_ name: String, properties: [String: Any]?) {
        CustomerIO.shared.track(name: name, properties: properties)
        flush()
    }
    
    @objc
    func screen(_ title: String, category: String?, properties: [String: Any]?) {
        CustomerIO.shared.screen(title: title, category: category, properties: properties)
        flush()
    }
    
    @objc
    func setProfileAttributes(_ attrs: [String: Any]) {
        CustomerIO.shared.profileAttributes = attrs
        flush()
    }
    
    @objc
    func setDeviceAttributes(_ attrs: [String: Any]) {
        CustomerIO.shared.deviceAttributes = attrs
        flush()
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
        CustomerioInAppMessaging.shared?.sendEvent(
            withName: CustomerioConstants.inAppEventListener,
            body: body
        )
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
