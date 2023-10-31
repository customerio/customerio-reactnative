import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public typealias HttpHeaders = [String: String]

public protocol HttpClient: AutoMockable {
    func request(
        _ params: HttpRequestParams,
        onComplete: @escaping (Result<Data, HttpRequestError>) -> Void
    )
    func downloadFile(url: URL, fileType: DownloadFileType, onComplete: @escaping (URL?) -> Void)
    func cancel(finishTasks: Bool)
}

// sourcery: InjectRegister = "HttpClient"
public class CIOHttpClient: HttpClient {
    private let baseUrls: HttpBaseUrls
    private var httpRequestRunner: HttpRequestRunner
    private let jsonAdapter: JsonAdapter
    private var globalDataStore: GlobalDataStore
    private let logger: Logger
    private let retryPolicyTimer: SimpleTimer
    private let retryPolicy: HttpRetryPolicy
    private let cioApiSession: URLSession // only used to call the CIO API.
    private let publicSession: URLSession // session used to call servers accessible to the public (such as CDNs)
    private var allSessions: [URLSession] {
        [cioApiSession, publicSession]
    }

    init(
        sdkConfig: SdkConfig,
        jsonAdapter: JsonAdapter,
        httpRequestRunner: HttpRequestRunner,
        globalDataStore: GlobalDataStore,
        logger: Logger,
        timer: SimpleTimer,
        retryPolicy: HttpRetryPolicy,
        userAgentUtil: UserAgentUtil
    ) {
        self.httpRequestRunner = httpRequestRunner
        self.baseUrls = sdkConfig.httpBaseUrls
        self.jsonAdapter = jsonAdapter
        self.globalDataStore = globalDataStore
        self.logger = logger
        self.retryPolicyTimer = timer
        self.retryPolicy = retryPolicy

        // Construct the URLSessions when the object is initialized and re-use them for all HTTP requests in the
        // lifecycle of this object.
        self.cioApiSession = Self.getCIOApiSession(
            siteId: sdkConfig.siteId,
            apiKey: sdkConfig.apiKey,
            userAgentHeaderValue: userAgentUtil.getUserAgentHeaderValue()
        )
        self.publicSession = Self.getBasicSession()
    }

    deinit {
        self.cancel(finishTasks: true)
    }

    public func downloadFile(url: URL, fileType: DownloadFileType, onComplete: @escaping (URL?) -> Void) {
        httpRequestRunner.downloadFile(
            url: url,
            fileType: fileType,
            session: getSessionForRequest(url: url),
            onComplete: onComplete
        )
    }

    public func request(_ params: HttpRequestParams, onComplete: @escaping (Result<Data, HttpRequestError>) -> Void) {
        if let httpPauseEnds = globalDataStore.httpRequestsPauseEnds, !httpPauseEnds.hasPassed {
            logger.debug("HTTP request ignored because requests are still paused.")
            return onComplete(.failure(.noRequestMade(nil)))
        }

        httpRequestRunner
            .request(
                params: params,
                session: getSessionForRequest(url: params.url)
            ) { [weak self] data, response, error in
                guard let self = self else { return }

                if let error = error {
                    if let error = self.isUrlError(error) {
                        return onComplete(.failure(error))
                    }

                    return onComplete(.failure(.noRequestMade(error)))
                }

                guard let response = response else {
                    return onComplete(.failure(.noRequestMade(nil)))
                }

                let statusCode = response.statusCode
                guard statusCode < 300 else {
                    return self.handleUnsuccessfulStatusCodeResponse(
                        statusCode: statusCode,
                        data: data,
                        params: params,
                        onComplete: onComplete
                    )
                }

                guard let data = data else {
                    return onComplete(.failure(.noRequestMade(nil)))
                }

                onComplete(.success(data))
            }
    }

    private func getErrorMessageFromServerResponse(responseBody: Data?) -> String {
        guard let data = responseBody, var errorBodyString = data.string else {
            return "(server did not give a response)"
        }

        // don't log errors for JSON mapping since we are trying to decode *multiple* error classes.
        // we are bound to fail more often and don't want to log errors that are not super helpful to us.
        if let errorMessageBody: ErrorMessageResponse = jsonAdapter.fromJson(
            data,
            logErrors: false
        ) {
            errorBodyString = errorMessageBody.meta.error
        } else if let errorMessageBody: ErrorsMessageResponse = jsonAdapter.fromJson(
            data,
            logErrors: false
        ) {
            errorBodyString = errorMessageBody.meta.errors.joined(separator: ",")
        }
        return errorBodyString
    }

    public func cancel(finishTasks: Bool) {
        if finishTasks {
            allSessions.forEach { $0.finishTasksAndInvalidate() }
        } else {
            allSessions.forEach { $0.invalidateAndCancel() }
        }
    }

    private func isUrlError(_ error: Error) -> HttpRequestError? {
        guard let urlError = error as? URLError else { return nil }

        switch urlError.code {
        case .notConnectedToInternet, .networkConnectionLost, .timedOut:
            return .noOrBadNetwork(urlError)
        case .cancelled:
            return .cancelled
        default: return nil
        }
    }
}

extension CIOHttpClient {
    static func getBasicSession() -> URLSession {
        let urlSessionConfig = URLSessionConfiguration.ephemeral

        urlSessionConfig.allowsCellularAccess = true
        urlSessionConfig.timeoutIntervalForResource = 30
        urlSessionConfig.timeoutIntervalForRequest = 60
        urlSessionConfig.httpAdditionalHeaders = [:]

        return URLSession(configuration: urlSessionConfig, delegate: nil, delegateQueue: nil)
    }

    static func getCIOApiSession(
        siteId: String,
        apiKey: String,
        userAgentHeaderValue: String
    ) -> URLSession {
        let urlSessionConfig = getBasicSession().configuration
        let basicAuthHeaderString = "Basic \(getBasicAuthHeaderString(siteId: siteId, apiKey: apiKey))"

        urlSessionConfig.httpAdditionalHeaders = ["Content-Type": "application/json; charset=utf-8",
                                                  "Authorization": basicAuthHeaderString,
                                                  "User-Agent": userAgentHeaderValue]

        return URLSession(configuration: urlSessionConfig, delegate: nil, delegateQueue: nil)
    }

    // Each URLSession used in this object are designed to request specific servers. Mostly in the HTTP header values
    // being added.
    // Choose what URLSession at runtime by the hostname of the URL being contacted in the request.
    func getSessionForRequest(url: URL) -> URLSession {
        let cioApiHostname = URL(string: baseUrls.trackingApi)!.host
        let requestHostname = url.host
        let isRequestToCIOApi = cioApiHostname == requestHostname

        return isRequestToCIOApi ? cioApiSession : publicSession
    }

    static func getBasicAuthHeaderString(siteId: String, apiKey: String) -> String {
        let rawHeader = "\(siteId):\(apiKey)"
        let encodedRawHeader = rawHeader.data(using: .utf8)!

        return encodedRawHeader.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
    }

    // In certain scenarios, it makes sense for us to pause making any HTTP requests to the
    // Customer.io API. Because HTTP requests are performed by the background queue, there is
    // a chance that the background queue could make a lot or more HTTP requests in
    // a short amount of time from a device which makes a performance impact on our API.
    // By pausing HTTP requests, we mitigate the chance of customer devices causing harm to our API.
    private func pauseHttpRequests() {
        let minutesToPause = 5
        let dateToEndPause = Date().add(minutesToPause, .minute)

        globalDataStore.httpRequestsPauseEnds = dateToEndPause

        logger.info("All HTTP requests to the Customer.io API have been paused for \(minutesToPause) minutes.")
    }

    /**
     - When receiving a 5xx response:
     * Begin an exponential backoff retry on the HTTP task that returned back the 5xx error.
     * After these retry attempts, if the HTTP request is still receiving a 5xx response then the
       requests will sleep for 5 minutes and no requests will be attempted.
     * After the 5 minutes, HTTP requests are able to be run as normal. No memory of any errors prior.

     - When receiving a 401 response:
     * The HTTP requests will sleep for 5 minutes as above.

     - Any other 4xx error
     * Log the error as it's more then likely a SDK developer error or an error by the customer.
     */
    private func handleUnsuccessfulStatusCodeResponse(
        statusCode: Int,
        data: Data?,
        params: HttpRequestParams,
        onComplete: @escaping (Result<Data, HttpRequestError>) -> Void
    ) {
        let unsuccessfulStatusCodeError: HttpRequestError =
            .unsuccessfulStatusCode(
                statusCode,
                apiMessage: getErrorMessageFromServerResponse(responseBody: data)
            )

        switch statusCode {
        case 500 ..< 600:
            if let sleepTime = retryPolicy.nextSleepTime {
                logger
                    .debug("""
                    Encountered \(statusCode) HTTP response.
                    Sleeping \(sleepTime) seconds and then retrying.
                    """)

                retryPolicyTimer.scheduleAndCancelPrevious(seconds: sleepTime) {
                    self.request(params, onComplete: onComplete)
                }
            } else {
                pauseHttpRequests()

                onComplete(.failure(unsuccessfulStatusCodeError))
            }
        case 401:
            pauseHttpRequests()

            onComplete(.failure(.unauthorized))
        case 400:
            onComplete(.failure(.badRequest400(apiMessage: getErrorMessageFromServerResponse(responseBody: data))))
        default:
            logger.error("""
            \(statusCode) HTTP status code response.
            Probably a bug? \(unsuccessfulStatusCodeError.localizedDescription)
            """)

            onComplete(.failure(unsuccessfulStatusCodeError))
        }
    }
}
