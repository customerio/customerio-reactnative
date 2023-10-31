import Foundation

public struct RegisterPushNotificationQueueTaskData: Codable {
    public let profileIdentifier: String
    public let attributesJsonString: String?

    public init(profileIdentifier: String, attributesJsonString: String?) {
        self.profileIdentifier = profileIdentifier
        self.attributesJsonString = attributesJsonString
    }

    enum CodingKeys: String, CodingKey {
        case profileIdentifier = "profile_identifier"
        case attributesJsonString = "attributes_json_string"
    }
}
