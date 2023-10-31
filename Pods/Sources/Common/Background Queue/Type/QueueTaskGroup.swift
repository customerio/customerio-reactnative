import Foundation

public enum QueueTaskGroup {
    case identifiedProfile(identifier: String)
    case registeredPushToken(token: String)

    public var string: String {
        switch self {
        case .identifiedProfile(let identifier): return "identified_profile_\(identifier)"
        case .registeredPushToken(let token): return "registered_push_token\(token)"
        }
    }
}
