import Foundation

class GistQueueNetwork {
    let siteId: String
    let dataCenter: String
    let userToken: String?

    init(siteId: String, dataCenter: String, userToken: String? = nil) {
        self.siteId = siteId
        self.dataCenter = dataCenter
        self.userToken = userToken
    }

    typealias GistNetworkResponse = (Data, HTTPURLResponse)

    func request(
        _ request: GistNetworkRequest,
        completionHandler: @escaping (Result<GistNetworkResponse, Error>) -> Void
    ) throws {
        guard let baseURL = URL(string: Settings.Network.queueAPI) else {
            throw GistNetworkRequestError.invalidBaseURL
        }

        var urlRequest = URLRequest(url: baseURL.appendingPathComponent(request.path))
        urlRequest.httpMethod = request.method.rawValue
        urlRequest.addValue(siteId, forHTTPHeaderField: HTTPHeader.siteId.rawValue)
        urlRequest.addValue(dataCenter, forHTTPHeaderField: HTTPHeader.cioDataCenter.rawValue)
        if let userToken = userToken {
            urlRequest.addValue(Data(userToken.utf8).base64EncodedString(), forHTTPHeaderField: HTTPHeader.userToken.rawValue)
        }
        urlRequest.addValue(ContentTypes.json.rawValue, forHTTPHeaderField: HTTPHeader.contentType.rawValue)

        try BaseNetwork.request(
            request,
            urlRequest: urlRequest,
            baseURL: baseURL,
            completionHandler: completionHandler
        )
    }
}
