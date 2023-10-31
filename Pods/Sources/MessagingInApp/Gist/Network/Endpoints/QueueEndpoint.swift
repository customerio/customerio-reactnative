import Foundation

enum QueueEndpoint: GistNetworkRequest {
    case getUserQueue

    var method: HTTPMethod {
        switch self {
        case .getUserQueue:
            return .post
        }
    }

    var parameters: RequestParameters? {
        nil
    }

    var path: String {
        switch self {
        case .getUserQueue:
            return "/api/v1/users"
        }
    }
}
