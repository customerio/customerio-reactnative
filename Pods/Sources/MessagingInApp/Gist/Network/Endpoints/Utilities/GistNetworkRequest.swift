protocol GistNetworkRequest {
    var method: HTTPMethod { get }
    var path: String { get }
    var parameters: RequestParameters? { get }
}

enum RequestParameters {
    case body(_: Encodable)
    case id(_: String)
}
