import Foundation

public struct HttpRequestParams {
    public let method: String
    public let url: URL
    public let headers: HttpHeaders?
    public let body: Data?

    /// Used to create params conveniently for the CIO API.
    public init?(endpoint: CIOApiEndpoint, baseUrls: HttpBaseUrls, headers: HttpHeaders?, body: Data?) {
        guard let url = endpoint.getUrl(baseUrls: baseUrls) else {
            return nil
        }

        self.method = endpoint.method
        self.url = url
        self.headers = headers
        self.body = body
    }

    /// swift's auto generated public init isn't accessible outside modules.
    public init(method: String, url: URL, headers: HttpHeaders?, body: Data?) {
        self.method = method
        self.url = url
        self.headers = headers
        self.body = body
    }
}
