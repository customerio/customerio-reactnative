
import React
import CioInternalCommon

typealias CioLogger = CioInternalCommon.Logger

@objc(CioLoggingEmitter)
class CioLoggingEmitter: RCTEventEmitter {
    
    fileprivate static var eventName = "CioLogEvent"
    
    fileprivate var hasObservers = false
    
    // Requires adding requiresMainQueueSetup method
    // since it overrides init
    @objc static override func requiresMainQueueSetup() -> Bool {
        return true // Return true if the module must be initialized on the main queue
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
}


class CioLoggerWrapper: CioLogger {
    private(set) var logLevel: CioLogLevel
    private var moduleRegistry: RCTModuleRegistry
    
    static func getInstance (moduleRegistry: RCTModuleRegistry, logLevel: CioLogLevel) -> CioLogger {
        if let wrapper = DIGraphShared.shared.logger as? Self  {
            wrapper.logLevel = logLevel
            wrapper.moduleRegistry = moduleRegistry
            return wrapper
        }
        
        let wrapper = CioLoggerWrapper(moduleRegistry: moduleRegistry, logLevel: logLevel)
        DIGraphShared.shared.override(value: wrapper, forType: CioLogger.self)
        return wrapper
    }
    
    private init(moduleRegistry: RCTModuleRegistry, logLevel: CioLogLevel?) {
        self.logLevel = logLevel ?? .none
        self.moduleRegistry = moduleRegistry
    }
    
    func setLogLevel(_ level: CioLogLevel) {
        logLevel = level
    }

    func debug(_ message: String) {
        emit(message, level: .debug)
    }
    
    func info(_ message: String) {
        emit(message, level: .info)
    }
    
    func error(_ message: String) {
        emit(message, level: .error)
    }
    
    private func emit(_ message: String, level: CioLogLevel) {
        if shouldEmit(level: level), let emitter, emitter.hasObservers {
            emitter.sendEvent(withName: CioLoggingEmitter.eventName, body: ["logLevel": level.rawValue, "message": message])
        }
    }
    
    private func shouldEmit(level: CioLogLevel) -> Bool {
        switch self.logLevel {
        case .none: return false
        case .error:
            return level == .error
        case .info:
            return level == .error || level == .info
        case .debug:
            return true
        }
    }
    
    private var emitter: CioLoggingEmitter? {
        moduleRegistry.module(forName: "CioLoggingEmitter") as? CioLoggingEmitter
    }
    
}
