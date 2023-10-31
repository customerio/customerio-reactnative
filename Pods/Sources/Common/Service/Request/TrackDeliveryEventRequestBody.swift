import Foundation

struct TrackDeliveryEventRequestBody: Codable {
    let type: DeliveryType
    let payload: DeliveryPayload

    enum CodingKeys: String, CodingKey {
        case type
        case payload
    }
}

struct DeliveryPayload: Codable {
    let deliveryId: String
    let event: InAppMetric
    let timestamp: Date
    let metaData: [String: String]

    enum CodingKeys: String, CodingKey {
        case deliveryId = "delivery_id"
        case event
        case timestamp
        case metaData = "metadata"
    }
}

enum DeliveryType: String, Codable {
    case inApp = "in_app"
}
