import CioInternalCommon
import CioDataPipelines
import CioMessagingInApp
import CioMessagingPush
import UserNotifications
import React
import CioAnalytics

@objc(CioRctWrapper)
class CioRctWrapper: NSObject {
    
    @objc var moduleRegistry: RCTModuleRegistry!
    private let logger: CioInternalCommon.Logger = DIGraphShared.shared.logger
    
    @objc(initialize:args:)
    func initialize(_ configJson: AnyObject, _ sdkArgs: AnyObject?) {
        do {
            guard let sdkConfig = configJson as? [String: Any?] else {
                logger.error("Initializing Customer.io SDK failed with error: Invalid config format")
                return
            }
            let sdkParams = sdkArgs as? [String: Any?]
            let packageSource = sdkParams?["packageSource"] as? String
            let packageVersion = sdkParams?["packageVersion"] as? String
            
            if let source = packageSource, let sdkVersion = packageVersion {
                DIGraphShared.shared.override(value: CustomerIOSdkClient(source: source, sdkVersion: sdkVersion), forType: SdkClient.self)
            }

            let sdkConfigBuilder = try SDKConfigBuilder.create(from: sdkConfig)
            CustomerIO.initialize(withConfig: sdkConfigBuilder.build())
            
            if let inAppConfig = try? MessagingInAppConfigBuilder.build(from: sdkConfig) {
                MessagingInApp.initialize(withConfig: inAppConfig)
                MessagingInApp.shared.setEventListener(self)
            }
            logger.debug("Customer.io SDK (\(packageSource ?? "") \(packageVersion ?? "")) initialized with config: \(configJson)")
        } catch {
            logger.error("Initializing Customer.io SDK failed with error: \(error)")
        }
    }
    
    @objc
    func identify(_ userId: String? = nil, traits: [String: Any]? = nil) {
        if let userId = userId {
            CustomerIO.shared.identify(userId: userId, traits: traits)
        } else if traits != nil {
            if let traitsJson = try? JSON(traits as Any) {
                CustomerIO.shared.identify(traits: traitsJson)
            } else {
                logger.error("Unable to parse traits to JSON: \(String(describing: traits))")
            }
        } else {
            logger.error("Provide id or traits to identify a user profile.")
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
    }
    
    @objc
    func setProfileAttributes(_ attrs: [String: Any]) {
        CustomerIO.shared.profileAttributes = attrs
    }
    
    @objc
    func setDeviceAttributes(_ attrs: [String: Any]) {
        CustomerIO.shared.deviceAttributes = attrs
    }
    
    @objc
    func registerDeviceToken(_ token: String){
        CustomerIO.shared.registerDeviceToken(token)
    }
    
    @objc
    func deleteDeviceToken(){
        CustomerIO.shared.deleteDeviceToken()
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
        CioRctInAppMessaging.shared?.sendEvent(
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
