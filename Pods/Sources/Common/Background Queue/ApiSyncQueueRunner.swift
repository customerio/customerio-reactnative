import Foundation

// base class for queue runner subclasses that perform networking
open class ApiSyncQueueRunner {
    public let jsonAdapter: JsonAdapter
    public let logger: Logger
    private let httpClient: HttpClient
    private let baseHttpUrls: HttpBaseUrls

    public let failureIfDontDecodeTaskData: Result<Void, HttpRequestError> = .failure(.noRequestMade(nil))

    public init(
        jsonAdapter: JsonAdapter,
        logger: Logger,
        httpClient: HttpClient,
        sdkConfig: SdkConfig
    ) {
        self.jsonAdapter = jsonAdapter
        self.logger = logger
        self.httpClient = httpClient
        self.baseHttpUrls = sdkConfig.httpBaseUrls
    }

    // (1) less code for `runTask` function to decode JSON and (2) one place to do error logging if decoding wrong.
    public func getTaskData<T: Decodable>(_ task: QueueTask, type: T.Type) -> T? {
        let taskData: T? = jsonAdapter.fromJson(task.data)

        if taskData == nil {
            // log as error because it's a developer error since SDK is who encoded the TaskData in the first place
            // we should always be able to decode it without problem.
            logger.error("Failure decoding: \(task.data.string ?? "()") to \(type)")
        }

        return taskData
    }

    public func performHttpRequest(
        endpoint: CIOApiEndpoint,
        requestBody: Data?,
        onComplete: @escaping (Result<Void, HttpRequestError>) -> Void
    ) {
        guard let httpParams = HttpRequestParams(
            endpoint: endpoint,
            baseUrls: baseHttpUrls,
            headers: nil,
            body: requestBody
        ) else {
            logger.error("Error constructing HTTP request. Endpoint: \(endpoint), baseUrls: \(baseHttpUrls)")
            return onComplete(.failure(.noRequestMade(nil)))
        }

        httpClient.request(httpParams) { result in
            switch result {
            case .success: onComplete(.success(()))
            case .failure(let httpError): onComplete(.failure(httpError))
            }
        }
    }
}
