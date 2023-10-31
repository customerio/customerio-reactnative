import CioInternalCommon
import Foundation

// https://customer.io/docs/api/#operation/pushMetrics
public struct MetricRequest: Codable {
    public let deliveryId: String
    public let event: Metric
    public let deviceToken: String
    public let timestamp: Date

    public init(deliveryId: String, event: Metric, deviceToken: String, timestamp: Date) {
        self.deliveryId = deliveryId
        self.event = event
        self.deviceToken = deviceToken
        self.timestamp = timestamp
    }

    enum CodingKeys: String, CodingKey {
        case deliveryId = "delivery_id"
        case event
        case deviceToken = "device_id"
        case timestamp
    }
}

extension MetricRequest {
    static var random: MetricRequest {
        MetricRequest(deliveryId: String.random, event: .opened, deviceToken: String.random, timestamp: Date())
    }
}
