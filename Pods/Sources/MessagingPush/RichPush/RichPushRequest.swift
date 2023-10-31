import CioInternalCommon
import Foundation
#if canImport(UserNotifications)
import UserNotifications

class RichPushRequest {
    private let completionHandler: (UNNotificationContent) -> Void
    private let pushContent: CustomerIOParsedPushPayload
    private let httpClient: HttpClient

    init(
        pushContent: CustomerIOParsedPushPayload,
        request: UNNotificationRequest,
        httpClient: HttpClient,
        completionHandler: @escaping (UNNotificationContent) -> Void
    ) {
        self.completionHandler = completionHandler
        self.pushContent = pushContent
        self.httpClient = httpClient
    }

    func start() {
        guard let image = pushContent.image else {
            // no async operations or modifications to the notification to do. Therefore, let's just finish.
            return finishImmediately()
        }

        httpClient.downloadFile(url: image, fileType: .richPushImage) { [weak self] localFilePath in
            guard let self = self else { return }

            if let localFilePath = localFilePath {
                self.pushContent.addImage(localFilePath: localFilePath)
            }

            self.finishImmediately()
        }
    }

    func finishImmediately() {
        httpClient.cancel(finishTasks: false)

        completionHandler(pushContent.mutableNotificationContent)
    }
}
#endif
