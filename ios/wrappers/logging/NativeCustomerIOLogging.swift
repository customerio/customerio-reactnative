import CioInternalCommon
import Foundation
import React

@objc(NativeCustomerIOLogging)
public class NativeCustomerIOLogging: RCTEventEmitter {
    // Event name constant
    private static var eventName = "CioLogEvent"

    // Reference to the event emitter for new architecture (TurboModule)
    private weak var eventEmitter: AnyObject?

    @objc
    override public init() {
        super.init()
        // Manually calling `initialize` for old arch, which doesn't invoke it automatically.
        // New arch will call it again, but it's safe since it just reassigns the same listener.
        initialize()
    }

    deinit {
        clearLogEventListener()
    }

    // Clears the log dispatcher to prevent memory leaks when module is deallocated or invalidated
    private func clearLogEventListener() {
        DIGraphShared.shared.logger.setLogDispatcher(nil)
    }

    // Set event emitter reference for new architecture
    @objc
    public func setEventEmitter(_ emitter: AnyObject) {
        eventEmitter = emitter
    }

    // Initialize log dispatcher - called by React Native
    @objc
    public func initialize() {
        DIGraphShared.shared.logger.setLogDispatcher { [weak self] level, message in
            guard let self else { return }

            self.sendLogEvent(level: level.rawValue, message: message)
        }
    }

    // Clear log dispatcher to prevent memory leaks - called by React Native
    @objc
    override public func invalidate() {
        super.invalidate()
        clearLogEventListener()
    }

    /**
     * Overriding supportedEvents method to return an array of supported event names.
     */
    override public func supportedEvents() -> [String]! {
        [Self.eventName]
    }

    override public var methodQueue: dispatch_queue_t! {
        DispatchQueue(label: Self.moduleName())
    }

    /**
     * Send log event to React Native layer
     * This method maintains compatibility with both architectures
     */
    @objc
    public func sendLogEvent(level: String, message: String) {
        let body = [
            "logLevel": level,
            "message": message
        ]

        if let emitter = eventEmitter {
            // New architecture: use injected event emitter from TurboModule
            let selector = Selector(("emitOnCioLogEvent:"))
            guard emitter.responds(to: selector) else {
                assertionFailure("Event emitter does not respond to selector: emitOnCioLogEvent:")
                return
            }
            _ = emitter.perform(selector, with: body as NSDictionary)
        } else {
            // Old architecture: use self as RCTEventEmitter
            super.sendEvent(withName: Self.eventName, body: body)
        }
    }
}
