import CioDataPipelines
import CioMessagingInApp
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
