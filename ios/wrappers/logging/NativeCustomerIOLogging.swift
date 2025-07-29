import CioInternalCommon
import Foundation
import React

// Core logging implementation shared between new and old architecture
private class NativeCustomerIOLoggingImplementation {
    private let logEventCallback: (_ body: [String: Any]) -> Void

    init(logEventCallback: @escaping (_ body: [String: Any]) -> Void) {
        self.logEventCallback = logEventCallback
    }

    // Initialize log dispatcher when module is ready
    func initialize() {
        DIGraphShared.shared.logger.setLogDispatcher { [weak self] level, message in
            guard let self else { return }

            let body = [
                "logLevel": level.rawValue,
                "message": message
            ]
            logEventCallback(body)
        }
    }

    // Clears the log dispatcher to prevent leaks when module is deallocated or invalidated
    func clearLogEventListener() {
        DIGraphShared.shared.logger.setLogDispatcher(nil)
    }

    // Clear log dispatcher to prevent leaks
    func invalidate() {
        clearLogEventListener()
    }
}

// Logging module for new React Native architecture (TurboModule)
@objc(NativeCustomerIOLogging)
public class NativeCustomerIOLogging: NSObject {
    private var implementation: NativeCustomerIOLoggingImplementation!
    // Reference to the ObjC event emitter for new architecture (TurboModule)
    private weak var objcEventEmitter: AnyObject?

    @objc
    override public init() {
        super.init()

        self.implementation = .init(logEventCallback: { [weak self] body in
            self?.sendEvent(body: body)
        })
    }

    // Set ObjC event emitter reference for new architecture
    @objc
    public func setEventEmitter(_ emitter: AnyObject) {
        objcEventEmitter = emitter
    }

    // Initialize log dispatcher - called by React Native
    @objc
    public func initialize() {
        implementation.initialize()
    }

    // Clear log dispatcher to prevent leaks - called by React Native
    @objc
    public func invalidate() {
        implementation.invalidate()
    }

    // Send log event to React Native layer using ObjC event emitter
    private func sendEvent(body: [String: Any]) {
        guard let emitter = objcEventEmitter else {
            assertionFailure("NativeCustomerIOLogging: ObjC event emitter is nil, cannot send log event")
            return
        }

        // New architecture: use injected ObjC event emitter from TurboModule
        let selector = Selector(("emitOnCioLogEvent:"))
        guard emitter.responds(to: selector) else {
            assertionFailure("ObjC event emitter does not respond to selector: emitOnCioLogEvent:")
            return
        }
        _ = emitter.perform(selector, with: body as NSDictionary)
    }
}

// Legacy logging module for old React Native architecture (pre-TurboModule)
@objc(NativeCustomerIOLoggingLegacy)
public class NativeCustomerIOLoggingLegacy: RCTEventEmitter {
    // Event name constant for log events
    private static var eventName = "CioLogEvent"

    private var implementation: NativeCustomerIOLoggingImplementation!

    @objc
    override public init() {
        super.init()

        self.implementation = .init(logEventCallback: { [weak self] body in
            guard let self else { return }

            // Old architecture: use self as RCTEventEmitter
            sendEvent(withName: Self.eventName, body: body)
        })
        initialize()
    }

    deinit {
        invalidate()
    }

    @objc
    public func initialize() {
        implementation.initialize()
    }

    @objc
    override public func invalidate() {
        implementation.invalidate()
        super.invalidate()
    }

    // Returns array of supported event names for RCTEventEmitter
    override public func supportedEvents() -> [String]! {
        [Self.eventName]
    }

    // Custom dispatch queue for logging operations
    override public var methodQueue: dispatch_queue_t! {
        DispatchQueue(label: Self.moduleName())
    }
}
