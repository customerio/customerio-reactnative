import Foundation

struct UserQueueResponse {
    let queueId: String
    let messageId: String
    let properties: [String: Any]?

    init(queueId: String, messageId: String, properties: [String: Any]?) {
        self.queueId = queueId
        self.messageId = messageId
        self.properties = properties
    }

    init?(dictionary: [String: Any?]) {
        guard let queueId = dictionary["queueId"] as? String,
              let messageId = dictionary["messageId"] as? String
        else {
            return nil
        }
        self.init(
            queueId: queueId,
            messageId: messageId,
            properties: dictionary["properties"] as? [String: Any]
        )
    }

    func toMessage() -> Message {
        Message(
            queueId: queueId,
            messageId: messageId,
            properties: properties
        )
    }
}
