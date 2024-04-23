import Foundation

class QueueManager {
    let siteId: String
    let dataCenter: String

    init(siteId: String, dataCenter: String) {
        self.siteId = siteId
        self.dataCenter = dataCenter
    }

    func fetchUserQueue(userToken: String, completionHandler: @escaping (Result<[UserQueueResponse]?, Error>) -> Void) {
        do {
            try GistQueueNetwork(siteId: siteId, dataCenter: dataCenter, userToken: userToken)
                .request(QueueEndpoint.getUserQueue, completionHandler: { response in
                    switch response {
                    case .success(let (data, response)):
                        self.updatePollingInterval(headers: response.allHeaderFields)
                        switch response.statusCode {
                        case 204:
                            completionHandler(.success([]))
                        case 304:
                            // No changes to the remote queue, returning nil so we don't clear local store.
                            completionHandler(.success(nil))
                        default:
                            do {
                                var userQueue = [UserQueueResponse]()
                                if let userQueueResponse =
                                    try JSONSerialization.jsonObject(
                                        with: data,
                                        options: .allowFragments
                                    ) as? [[String: Any?]] {
                                    userQueueResponse.forEach { item in
                                        if let userQueueItem = UserQueueResponse(dictionary: item) {
                                            userQueue.append(userQueueItem)
                                        }
                                    }
                                }
                                DispatchQueue.main.async {
                                    completionHandler(.success(userQueue))
                                }
                            } catch {
                                completionHandler(.failure(error))
                            }
                        }
                    case .failure(let error):
                        completionHandler(.failure(error))
                    }
                })
        } catch {
            completionHandler(.failure(error))
        }
    }

    private func updatePollingInterval(headers: [AnyHashable: Any]) {
        if let newPollingIntervalString = headers["x-gist-queue-polling-interval"] as? String,
           let newPollingInterval = Double(newPollingIntervalString),
           newPollingInterval != Gist.shared.messageQueueManager.interval {
            DispatchQueue.main.async {
                Gist.shared.messageQueueManager.interval = newPollingInterval
                Gist.shared.messageQueueManager.setup(skipQueueCheck: true)
                Logger.instance.info(message: "Polling interval changed to: \(newPollingInterval) seconds")
            }
        }
    }
}
