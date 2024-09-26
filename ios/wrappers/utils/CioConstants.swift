struct CustomerioConstants {
    // InApp Messaging
    static let inAppEventListener = "InAppEventListener"
    static let eventType = "eventType"
    static let messageId = "messageId"
    static let deliveryId = "deliveryId"
    static let actionValue = "actionValue"
    static let actionName = "actionName"
    static let messageShown = "messageShown"
    static let messageDismissed = "messageDismissed"
    static let errorWithMessage = "errorWithMessage"
    static let messageActionTaken = "messageActionTaken"
    
    // Push Messaging
    static let CioDeliveryId = "CIO-Delivery-ID"
    static let CioDeliveryToken = "CIO-Delivery-Token"
    static let showPromptFailureError = "Error requesting push notification permission."
    static let showDeviceTokenFailureError = "Error fetching registered device token."
    static let platformiOS = "ios"
    static let sound = "sound"
    static let badge = "badge"
    
    // Logging
    static let cioTag = "[CIO]"
    
    // DataPipelines
    static let initializeWithConfigMessage = "Initializing Customer.io SDK with config:"
    static let noIdOrTraitError = "Provide id or traits to identify a user profile."
    static let initializationFailedError = "Initializing Customer.io SDK failed with error"
}
