import Foundation

enum LogEndpoint: GistNetworkRequest {
    case logUserMessageView(queueId: String)
    case logMessageView(messageId: String)

    var method: HTTPMethod {
        switch self {
        case .logUserMessageView:
            return .post
        case .logMessageView:
            return .post
        }
    }

    var parameters: RequestParameters? {
        switch self {
        case .logUserMessageView(let queueId):
            return .id(queueId)
        case .logMessageView(let messageId):
            return .id(messageId)
        }
    }

    var path: String {
        switch self {
        case .logUserMessageView:
            return "/api/v1/logs/queue"
        case .logMessageView:
            return "/api/v1/logs/message"
        }
    }
}
