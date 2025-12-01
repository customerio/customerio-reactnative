import CioMessagingInApp
import Foundation
import React

// In-app messaging module for new React Native architecture (TurboModule)
@objc(NativeMessagingInApp)
public class NativeMessagingInApp: NSObject {
    // Reference to the ObjC event emitter for new architecture (TurboModule)
    private weak var objcEventEmitter: AnyObject?
    private lazy var inAppEventCallback: (_ body: [String: Any]) -> Void = { [weak self] body in
        self?.sendEvent(body: body)
    }

    // Set ObjC event emitter reference for new architecture
    @objc
    public func setEventEmitter(_ emitter: AnyObject) {
        objcEventEmitter = emitter
    }

    // Initialize in-app event listener - called by React Native
    @objc
    public func initialize() {
        // Initialize in-app event listener - called by React Native
        ReactInAppEventListener.shared.setEventEmitter { [weak self] data in
            guard let self else { return }

            // Filter out nil values to convert [String: Any?] to [String: Any]
            let body = data.compactMapValues { $0 }
            inAppEventCallback(body)
        }
        // If MessagingInApp module has already been initialized, this sets the listener directly.
        // If this method is called early, accessing ReactInAppEventListener.shared will also register
        // it into the DI graph, making it available for access in Expo during auto-initialization.
        MessagingInApp.shared.setEventListener(ReactInAppEventListener.shared)
    }

    // Clear in-app event listener to prevent memory leaks - called by React Native
    @objc
    public func invalidate() {
        // Clear in-app event listener to prevent leaks
        clearInAppEventListener()
    }

    /**
     * Dismisses any currently displayed in-app message
     */
    @objc(dismissMessage)
    public func dismissMessage() {
        MessagingInApp.shared.dismissMessage()
    }

    // Clears the in-app event listener to prevent leaks when module is deallocated or invalidated
    func clearInAppEventListener() {
        ReactInAppEventListener.shared.clearEventEmitter()
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
