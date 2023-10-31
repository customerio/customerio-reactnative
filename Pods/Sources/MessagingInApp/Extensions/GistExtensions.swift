import Foundation

extension Message {
    // Used for getting details about the Message object for sending to logs.
    //
    // We are logging the Gist campaign id as delivery id because we call it delivery id on our system.
    var describeForLogs: String {
        "id: \(messageId), queueId: \(queueId ?? "none"), deliveryId: \(gistProperties.campaignId ?? "none")"
    }
}
