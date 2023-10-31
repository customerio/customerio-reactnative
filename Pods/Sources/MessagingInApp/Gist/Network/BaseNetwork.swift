import Foundation

typealias GistNetworkResponse = (Data, HTTPURLResponse)

enum GistNetworkError: Error {
    case serverError
    case requestFailed
}

enum BaseNetwork {
    static func request(
        _ request: GistNetworkRequest,
        urlRequest: URLRequest,
        baseURL: URL,
        completionHandler: @escaping (Result<GistNetworkResponse, Error>) -> Void
    ) throws {
        var urlRequest = urlRequest
        switch request.parameters {
        case .body(let body):
            urlRequest.httpBody = try JSONSerialization.data(withJSONObject: body.asDictionary(), options: [])
        case .id(let id):
            let components = URLComponents(string: baseURL
                .appendingPathComponent(request.path)
                .appendingPathComponent(id).absoluteString
            )
            urlRequest.url = components?.url
        default:
            break
        }

        URLSession.shared.dataTask(with: urlRequest, completionHandler: { data, response, error in
            if let error = error { completionHandler(.failure(error)) }
            guard let data = data, let response = response as? HTTPURLResponse,
                  (200 ... 299).contains(response.statusCode)
            else {
                completionHandler(.failure(GistNetworkError.serverError))
                return
            }
            completionHandler(.success(GistNetworkResponse(data, response)))
        }).resume()
    }
}
