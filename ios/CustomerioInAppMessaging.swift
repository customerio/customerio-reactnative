import Foundation
import React
@objc(CustomerioInAppMessaging)
class CustomerioInAppMessaging: RCTEventEmitter {
    public static var shared: CustomerioInAppMessaging?

    override init() {
        super.init()
        CustomerioInAppMessaging.shared = self
    }

    open override func supportedEvents() -> [String]! {
        return [
            "messageShown",
            "messageDismissed",
            "errorWithMessage",
            "errorWithMessage"
        ]
    }
}
