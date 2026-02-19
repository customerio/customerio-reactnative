import CioMessagingInApp
import Foundation

// MARK: - InboxMessage Conversion Extension

extension InboxMessage {
    /// Converts InboxMessage to dictionary for React Native bridge
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "queueId": queueId,
            "sentAt": sentAt.timeIntervalSince1970 * 1000, // Convert to milliseconds
            "topics": topics,
            "type": type,
            "opened": opened,
            "properties": properties
        ]

        if let deliveryId = deliveryId {
            dict["deliveryId"] = deliveryId
        }

        if let expiry = expiry {
            dict["expiry"] = expiry.timeIntervalSince1970 * 1000 // Convert to milliseconds
        }

        if let priority = priority {
            dict["priority"] = priority
        }

        return dict
    }
}
