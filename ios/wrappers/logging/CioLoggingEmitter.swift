
import React
import CioInternalCommon

@objc(CioLoggingEmitter)
class CioLoggingEmitter: RCTEventEmitter {
    
    fileprivate static var eventName = "CioLogEvent"
    
    fileprivate var hasObservers = false
    
    // Requires adding requiresMainQueueSetup method
    // since it overrides init
    @objc static override func requiresMainQueueSetup() -> Bool {
        return true // Return true if the module must be initialized on the main queue
    }
    
    override init() {
        super.init()

        DIGraphShared.shared.logger.setLogDispatcher { [weak self] level, message in
            guard let self else { return }
            
            emit(level: level, message: message)
        }
    }
    
    deinit {
        // Clear log dispatcher if the emitter has been deallocated
        DIGraphShared.shared.logger.setLogDispatcher(nil)
    }
    
    override func startObserving() {
        hasObservers = true
    }
    
    override func stopObserving() {
        hasObservers = false
    }
    
    override func supportedEvents() -> [String] {
        [Self.eventName]
    }
    
    override var methodQueue: dispatch_queue_t! {
        DispatchQueue(label: Self.moduleName())
    }
    
    private var emitter: CioLoggingEmitter? {
        moduleRegistry?.module(forName: "CioLoggingEmitter") as? CioLoggingEmitter
    }

    private func emit(level: CioLogLevel, message: String) {
        if let emitter, emitter.hasObservers {
            emitter.sendEvent(withName: CioLoggingEmitter.eventName, body: ["logLevel": level.rawValue, "message": message])
        }
    }
}
