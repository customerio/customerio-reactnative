import Foundation

public struct DeletePushNotificationQueueTaskData: Codable {
    public let profileIdentifier: String
    public let deviceToken: String

    public init(profileIdentifier: String, deviceToken: String) {
        self.profileIdentifier = profileIdentifier
        self.deviceToken = deviceToken
    }

    enum CodingKeys: String, CodingKey {
        case profileIdentifier = "profile_identifier"
        case deviceToken = "device_token"
    }
}
