import CioInternalCommon
import CioTracking
import Foundation
#if canImport(UserNotifications)
import UserNotifications

class RichPushRequestHandler {
    static let shared = RichPushRequestHandler()

    @Atomic private var requests: [String: RichPushRequest] = [:]

    private init() {}

    func startRequest(
        _ request: UNNotificationRequest,
        content: CustomerIOParsedPushPayload,
        completionHandler: @escaping (UNNotificationContent) -> Void
    ) {
        let requestId = request.identifier

        let existingRequest = requests[requestId]
        if existingRequest != nil { return }

        let sdkInitializedUtil = SdkInitializedUtilImpl()

        guard let postSdkInitializedData = sdkInitializedUtil.postInitializedData else { return }

        let diGraph = postSdkInitializedData.diGraph
        let httpClient = diGraph.httpClient

        let newRequest = RichPushRequest(
            pushContent: content,
            request: request,
            httpClient: httpClient,
            completionHandler: completionHandler
        )
        requests[requestId] = newRequest

        newRequest.start()
    }

    func stopAll() {
        requests.forEach {
            $0.value.finishImmediately()
        }

        requests = [:]
    }
}
#endif
