import Foundation

struct UserQueueResponse {
    let queueId: String
    let priority: Int
    let messageId: String
    let properties: [String: Any]?

    init(queueId: String, priority: Int, messageId: String, properties: [String: Any]?) {
        self.queueId = queueId
        self.priority = priority
        self.messageId = messageId
        self.properties = properties
    }

    init?(dictionary: [String: Any?]) {
        guard let queueId = dictionary["queueId"] as? String,
              let priority = dictionary["priority"] as? Int,
              let messageId = dictionary["messageId"] as? String
        else {
            return nil
        }
        self.init(
            queueId: queueId,
            priority: priority,
            messageId: messageId,
            properties: dictionary["properties"] as? [String: Any]
        )
    }

    func toMessage() -> Message {
        Message(
            queueId: queueId,
            priority: priority,
            messageId: messageId,
            properties: properties
        )
    }
}
