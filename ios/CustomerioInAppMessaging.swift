import Foundation
import React

@objc(CustomerioInAppMessaging)
class CustomerioInAppMessaging: RCTEventEmitter {
    public static var shared: CustomerioInAppMessaging?

    @objc override static func requiresMainQueueSetup() -> Bool {
        false /// false because our native module's initialization does not require access to UIKit
    }

    override init() {
        super.init()
        CustomerioInAppMessaging.shared = self
    }

    /**
     * Overriding supportedEvents method to return an array of supported event names.
     * We are combining in-app events against single name so only one event is added.
     */
    open override func supportedEvents() -> [String]! {
        return [ "InAppEventListener" ]
    }
}
