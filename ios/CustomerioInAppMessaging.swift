import Foundation
import React
@objc(CustomerioInAppMessaging)
class CustomerioInAppMessaging: RCTEventEmitter {
    public static var shared: CustomerioInAppMessaging?

    override init() {
        super.init()
        CustomerioInAppMessaging.shared = self
    }
}
