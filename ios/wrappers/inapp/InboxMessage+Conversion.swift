import CioMessagingInApp
import Foundation

// MARK: - InboxMessage Conversion Extension

extension InboxMessage {
    /// Converts InboxMessage to dictionary for React Native bridge
    /// Note: Uses NSNull for nil optional values to match Android behavior (explicit null vs undefined)
    func toDictionary() -> [String: Any] {
        return [
            "queueId": queueId,
            "deliveryId": deliveryId ?? NSNull(),
            "sentAt": sentAt.timeIntervalSince1970 * 1000, // Convert to milliseconds
            "expiry": expiry.map { $0.timeIntervalSince1970 * 1000 } ?? NSNull(),
            "type": type,
            "opened": opened,
            "topics": topics,
            "priority": priority ?? NSNull(),
            "properties": properties
        ]
    }
}
