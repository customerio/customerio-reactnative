import CioMessagingInApp
import Foundation
import React

@objc(NativeMessagingInApp)
public class NativeMessagingInApp: RCTEventEmitter {
    // Reference to the event emitter for new architecture (TurboModule)
    private weak var eventEmitter: AnyObject?

    @objc
    override public init() {
        super.init()
        // Manually calling `initialize` for old arch, which doesn't invoke it automatically.
        // New arch will call it again, but it's safe since it just reassigns the same listener.
        initialize()
    }

    // Set event emitter reference for new architecture
    @objc
    public func setEventEmitter(_ emitter: AnyObject) {
        eventEmitter = emitter
    }

    // Initialize event listener - called by React Native
    @objc
    public func initialize() {
        ReactInAppEventListener.shared.setEventEmitter { data in
            // Filter out nil values to convert [String: Any?] to [String: Any]
            let body = data.compactMapValues { $0 }
            self.sendInAppEvent(withName: CustomerioConstants.inAppEventListener, body: body)
        }
    }

    // Clear event listener to prevent memory leaks - called by React Native
    @objc
    override public func invalidate() {
        ReactInAppEventListener.shared.clearEventEmitter()
    }

    /**
     * Overriding supportedEvents method to return an array of supported event names.
     * We are combining in-app events against single name so only one event is added.
     */
    override public func supportedEvents() -> [String]! {
        [CustomerioConstants.inAppEventListener]
    }

    /**
     * Dismisses any currently displayed in-app message
     */
    @objc(dismissMessage)
    public func dismissMessage() {
        MessagingInApp.shared.dismissMessage()
    }

    /**
     * Send in-app event to React Native layer
     * This method maintains compatibility with both architectures
     */
    @objc
    public func sendInAppEvent(withName name: String, body: [String: Any]) {
        if let emitter = eventEmitter {
            // New architecture: use injected event emitter from TurboModule
            let selector = Selector(("emitOnInAppEventReceived:"))
            guard emitter.responds(to: selector) else {
                assertionFailure("Event emitter does not respond to selector: emitOnInAppEventReceived:")
                return
            }
            _ = emitter.perform(selector, with: body as NSDictionary)
        } else {
            // Old architecture: use self as RCTEventEmitter
            super.sendEvent(withName: name, body: body)
        }
    }
}
