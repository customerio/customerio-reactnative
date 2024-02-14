import CioInternalCommon
import Foundation

class RichPushRequest {
    private let completionHandler: (PushNotification) -> Void
    private var push: PushNotification
    private let httpClient: HttpClient

    init(
        push: PushNotification,
        httpClient: HttpClient,
        completionHandler: @escaping (PushNotification) -> Void
    ) {
        self.completionHandler = completionHandler
        self.push = push
        self.httpClient = httpClient
    }

    func start() {
        guard let image = push.cioImage?.url else {
            // no async operations or modifications to the notification to do. Therefore, let's just finish.
            return finishImmediately()
        }

        httpClient.downloadFile(url: image, fileType: .richPushImage) { [weak self] localFilePath in
            guard let self = self else { return }

            if let localFilePath = localFilePath {
                self.push.cioRichPushImageFile = localFilePath
            }

            self.finishImmediately()
        }
    }

    func finishImmediately() {
        httpClient.cancel(finishTasks: false)

        completionHandler(push)
    }
}
