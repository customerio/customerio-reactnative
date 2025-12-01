import CioInternalCommon
import Foundation
import React

// Logging module for new React Native architecture (TurboModule)
@objc(NativeCustomerIOLogging)
public class NativeCustomerIOLogging: NSObject {
    // Reference to the ObjC event emitter for new architecture (TurboModule)
    private weak var objcEventEmitter: AnyObject?
    private lazy var logEventCallback: (_ body: [String: Any]) -> Void = { [weak self] body in
        self?.sendEvent(body: body)
    }

    // Set ObjC event emitter reference for new architecture
    @objc
    public func setEventEmitter(_ emitter: AnyObject) {
        objcEventEmitter = emitter
    }

    // Initialize log dispatcher - called by React Native
    @objc
    public func initialize() {
        // Initialize log dispatcher when module is ready
        DIGraphShared.shared.logger.setLogDispatcher { [weak self] level, message in
            guard let self else { return }

            let body = [
                "logLevel": level.rawValue,
                "message": message
            ]
            logEventCallback(body)
        }
    }

    // Clear log dispatcher to prevent leaks - called by React Native
    @objc
    public func invalidate() {
        // Clear log dispatcher to prevent leaks
        clearLogEventListener()
    }

    // Clears the log dispatcher to prevent leaks when module is deallocated or invalidated
    private func clearLogEventListener() {
        DIGraphShared.shared.logger.setLogDispatcher(nil)
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
