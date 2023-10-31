import Foundation

/**
 Errors that can happen during an HTTP request.
 */
public enum HttpRequestError: Error {
    /// 401 status code. Probably need to re-configure SDK with valid credentials.
    case unauthorized
    /// HTTP URL for the request not a valid URL.
    case urlConstruction(_ url: String)
    /// A response came back, but status code > 300 and not handled already (example: 401)
    case unsuccessfulStatusCode(_ code: Int, apiMessage: String)
    /// No Internet connection or bad network connection
    case noOrBadNetwork(_ urlError: URLError)
    /// Request was not able to get a response from server. Maybe no network connection?
    case noRequestMade(_ error: Error?)
    /// 400 status code. The request body contains errors or is malformed.
    case badRequest400(apiMessage: String)
    /// HTTP requests are paused so the request was not made
    case requestsPaused
    /// Request was cancelled.
    case cancelled
}

extension HttpRequestError: CustomStringConvertible, LocalizedError {
    /// Custom description for the Error to describe the error that happened.
    public var description: String {
        switch self {
        case .unauthorized: return "HTTP request responded with 401. Configure the SDK with valid credentials."
        case .urlConstruction(let url): return "HTTP URL not a valid URL: \(url)"
        case .unsuccessfulStatusCode(let code, let apiMessage):
            return "Response received, but status code = \(String(code)). \(apiMessage)"
        case .noOrBadNetwork: return "No Internet connection or bad network connection."
        case .badRequest400(let apiMessage):
            return "HTTP request responded with 400 - \(apiMessage)"
        case .noRequestMade(let error): return error?
            .localizedDescription ?? "No request was able to be made to server."
        case .requestsPaused: return "HTTP request skipped. All HTTP requests are paused for the time being."
        case .cancelled: return "Request was cancelled"
        }
    }
}
