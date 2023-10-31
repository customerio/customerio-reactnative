import Foundation

public struct TrackEventQueueTaskData: Codable {
    public let identifier: String
    /// JSON string: '{"foo": "bar"}'
    public let attributesJsonString: String

    public init(identifier: String, attributesJsonString: String) {
        self.identifier = identifier
        self.attributesJsonString = attributesJsonString
    }

    enum CodingKeys: String, CodingKey {
        case identifier
        case attributesJsonString = "attributes_json_string"
    }
}
