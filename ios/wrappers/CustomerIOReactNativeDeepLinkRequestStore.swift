import Foundation

struct CustomerIOReactNativeDeepLinkRequestStore {
    enum Acceptance: Equatable {
        case buffered(UUID)
        case linking(URL)
        case handler(UUID, URL)
    }

    enum Resolution: Equatable {
        case handled
        case fallback(URL)
    }

    private enum DeliveryMode: Equatable {
        case unavailable
        case linking
        case handler
    }

    private enum RequestState: Equatable {
        case buffered
        case awaitingAcknowledgement
    }

    private struct Request {
        let id: UUID
        let url: URL
        var state: RequestState
    }

    private var isLinkingReady = false
    private var requiresHandler = false
    private var hasHandler = false
    private var requests: [Request] = []

    private var deliveryMode: DeliveryMode {
        if hasHandler {
            return .handler
        }
        if !requiresHandler, isLinkingReady {
            return .linking
        }
        return .unavailable
    }

    var requiresAcknowledgedHandler: Bool {
        requiresHandler
    }

    mutating func requireAcknowledgedHandler() {
        requiresHandler = true
    }

    mutating func accept(_ url: URL) -> Acceptance {
        switch deliveryMode {
        case .unavailable:
            let request = Request(id: UUID(), url: url, state: .buffered)
            requests.append(request)
            return .buffered(request.id)
        case .linking:
            return .linking(url)
        case .handler:
            let request = Request(id: UUID(), url: url, state: .awaitingAcknowledgement)
            requests.append(request)
            return .handler(request.id, request.url)
        }
    }

    mutating func useLinking() -> [URL] {
        isLinkingReady = true
        guard deliveryMode == .linking else { return [] }

        let urls = requests.compactMap { request in
            request.state == .buffered ? request.url : nil
        }
        requests.removeAll { $0.state == .buffered }
        return urls
    }

    mutating func useHandler() -> [(UUID, URL)] {
        hasHandler = true
        var deliveries: [(UUID, URL)] = []
        for index in requests.indices where requests[index].state == .buffered {
            requests[index].state = .awaitingAcknowledgement
            deliveries.append((requests[index].id, requests[index].url))
        }
        return deliveries
    }

    mutating func removeHandler() -> [UUID] {
        guard hasHandler else { return [] }
        hasHandler = false

        var replacementIds: [UUID] = []
        for index in requests.indices where requests[index].state == .awaitingAcknowledgement {
            let replacementId = UUID()
            requests[index] = Request(
                id: replacementId,
                url: requests[index].url,
                state: .buffered
            )
            replacementIds.append(replacementId)
        }
        return replacementIds
    }

    mutating func acknowledge(_ id: UUID, handled: Bool) -> Resolution? {
        guard let index = requests.firstIndex(where: {
            $0.id == id && $0.state == .awaitingAcknowledgement
        }) else { return nil }

        let url = requests.remove(at: index).url
        return handled ? .handled : .fallback(url)
    }

    mutating func expireReadiness(_ id: UUID) -> URL? {
        expire(id, expectedState: .buffered)
    }

    mutating func expireAcknowledgement(_ id: UUID) -> URL? {
        expire(id, expectedState: .awaitingAcknowledgement)
    }

    private mutating func expire(_ id: UUID, expectedState: RequestState) -> URL? {
        guard let index = requests.firstIndex(where: {
            $0.id == id && $0.state == expectedState
        }) else { return nil }

        return requests.remove(at: index).url
    }
}
