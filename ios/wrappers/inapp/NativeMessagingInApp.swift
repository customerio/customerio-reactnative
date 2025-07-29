import CioMessagingInApp
import Foundation
import React

// Core in-app messaging implementation shared between new and old architecture
class NativeMessagingInAppImplementation {
    private let inAppEventCallback: (_ body: [String: Any]) -> Void

    init(inAppEventCallback: @escaping (_ body: [String: Any]) -> Void) {
        self.inAppEventCallback = inAppEventCallback
    }

    // Initialize in-app event listener - called by React Native
    func initialize() {
        ReactInAppEventListener.shared.setEventEmitter { [weak self] data in
            guard let self else { return }

            // Filter out nil values to convert [String: Any?] to [String: Any]
            let body = data.compactMapValues { $0 }
            inAppEventCallback(body)
        }
    }

    // Clears the in-app event listener to prevent leaks when module is deallocated or invalidated
    func clearInAppEventListener() {
        ReactInAppEventListener.shared.clearEventEmitter()
    }

    // Clear in-app event listener to prevent leaks
    func invalidate() {
        clearInAppEventListener()
    }
}

// In-app messaging module for new React Native architecture (TurboModule)
@objc(NativeMessagingInApp)
public class NativeMessagingInApp: NSObject {
    private var implementation: NativeMessagingInAppImplementation!
    // Reference to the ObjC event emitter for new architecture (TurboModule)
    private weak var objcEventEmitter: AnyObject?

    @objc
    override public init() {
        super.init()

        self.implementation = .init(inAppEventCallback: { [weak self] body in
            self?.sendEvent(body: body)
        })
    }

    // Set ObjC event emitter reference for new architecture
    @objc
    public func setEventEmitter(_ emitter: AnyObject) {
        objcEventEmitter = emitter
    }

    // Initialize in-app event listener - called by React Native
    @objc
    public func initialize() {
        implementation.initialize()
    }

    // Clear in-app event listener to prevent memory leaks - called by React Native
    @objc
    public func invalidate() {
        implementation.invalidate()
    }

    /**
     * Dismisses any currently displayed in-app message
     */
    @objc(dismissMessage)
    public func dismissMessage() {
        MessagingInApp.shared.dismissMessage()
    }

    // Send in-app event to React Native layer using ObjC event emitter
    private func sendEvent(body: [String: Any]) {
        guard let emitter = objcEventEmitter else {
            assertionFailure("NativeMessagingInApp: ObjC event emitter is nil, cannot send in-app event")
            return
        }

        // New architecture: use injected ObjC event emitter from TurboModule
        let selector = Selector(("emitOnInAppEventReceived:"))
        guard emitter.responds(to: selector) else {
            assertionFailure("ObjC event emitter does not respond to selector: emitOnInAppEventReceived:")
            return
        }
        _ = emitter.perform(selector, with: body as NSDictionary)
    }
}

// Legacy in-app messaging module for old React Native architecture (pre-TurboModule)
@objc(NativeMessagingInAppLegacy)
public class NativeMessagingInAppLegacy: RCTEventEmitter {
    private var implementation: NativeMessagingInAppImplementation!

    @objc
    override public init() {
        super.init()

        self.implementation = .init(inAppEventCallback: { [weak self] body in
            guard let self else { return }

            // Old architecture: use self as RCTEventEmitter
            sendEvent(withName: CustomerioConstants.inAppEventListener, body: body)
        })
        initialize()
    }

    deinit {
        invalidate()
    }

    // Initialize in-app event listener - called by React Native
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
    // All in-app events are combined under a single event name
    override public func supportedEvents() -> [String]! {
        [CustomerioConstants.inAppEventListener]
    }
}
