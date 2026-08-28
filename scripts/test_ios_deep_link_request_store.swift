import Foundation

private func require(_ condition: @autoclosure () -> Bool, _ message: String) {
    guard condition() else {
        fputs("error: \(message)\n", stderr)
        exit(1)
    }
}

private func bufferedRequest(
    _ acceptance: CustomerIOReactNativeDeepLinkRequestStore.Acceptance
) -> UUID {
    guard case let .buffered(id) = acceptance else {
        fputs("error: expected a buffered request\n", stderr)
        exit(1)
    }
    return id
}

private func handlerRequest(
    _ acceptance: CustomerIOReactNativeDeepLinkRequestStore.Acceptance
) -> UUID {
    guard case let .handler(id, _) = acceptance else {
        fputs("error: expected a handler request\n", stderr)
        exit(1)
    }
    return id
}

@main
private enum DeepLinkRequestStoreTests {
    static func main() {
        let coldUrl = URL(string: "myapp://cold")!
        var lateStore = CustomerIOReactNativeDeepLinkRequestStore()
        let coldId = bufferedRequest(lateStore.accept(coldUrl))
        let replay = lateStore.useHandler()
        require(replay.count == 1, "late handler must receive one buffered URL")
        require(replay[0].0 == coldId, "replay must preserve the request ID")
        require(replay[0].1 == coldUrl, "replay must preserve the URL")
        require(
            lateStore.acknowledge(coldId, handled: true) == .handled,
            "handled acknowledgement must resolve the request"
        )
        require(
            lateStore.expireAcknowledgement(coldId) == nil,
            "resolved request must not fall back after its timeout"
        )

        let declinedUrl = URL(string: "https://example.com/declined")!
        var declinedStore = CustomerIOReactNativeDeepLinkRequestStore()
        _ = declinedStore.useHandler()
        let declinedId = handlerRequest(declinedStore.accept(declinedUrl))
        require(
            declinedStore.acknowledge(declinedId, handled: false) == .fallback(declinedUrl),
            "declined request must select fallback"
        )
        require(
            declinedStore.acknowledge(declinedId, handled: true) == nil,
            "request must resolve exactly once"
        )

        let absentUrl = URL(string: "myapp://absent")!
        var absentStore = CustomerIOReactNativeDeepLinkRequestStore()
        let absentId = bufferedRequest(absentStore.accept(absentUrl))
        require(
            absentStore.expireReadiness(absentId) == absentUrl,
            "missing handler must fall back after the readiness timeout"
        )
        require(
            absentStore.useHandler().isEmpty,
            "an expired request must not replay to a late handler"
        )

        let timeoutUrl = URL(string: "myapp://timeout")!
        var timeoutStore = CustomerIOReactNativeDeepLinkRequestStore()
        _ = timeoutStore.useHandler()
        let timeoutId = handlerRequest(timeoutStore.accept(timeoutUrl))
        require(
            timeoutStore.expireAcknowledgement(timeoutId) == timeoutUrl,
            "unacknowledged handler request must fall back"
        )
        require(
            timeoutStore.acknowledge(timeoutId, handled: true) == nil,
            "late acknowledgement must not resolve an expired request"
        )

        let linkingUrl = URL(string: "myapp://legacy-linking")!
        var linkingStore = CustomerIOReactNativeDeepLinkRequestStore()
        let linkingId = bufferedRequest(linkingStore.accept(linkingUrl))
        require(
            linkingStore.useLinking() == [linkingUrl],
            "legacy Linking readiness must replay buffered URLs"
        )
        require(
            linkingStore.expireReadiness(linkingId) == nil,
            "a URL replayed to Linking must not later fall back"
        )

        let handlerUrl = URL(string: "myapp://handler-wins")!
        var handlerStore = CustomerIOReactNativeDeepLinkRequestStore()
        _ = handlerStore.useHandler()
        let handlerId = handlerRequest(handlerStore.accept(handlerUrl))
        require(
            handlerStore.useLinking().isEmpty,
            "initialization must not replace an explicit handler with Linking"
        )
        require(
            handlerStore.acknowledge(handlerId, handled: true) == .handled,
            "explicit handler must remain able to acknowledge the URL"
        )

        let requiredUrl = URL(string: "myapp://required-handler")!
        var requiredStore = CustomerIOReactNativeDeepLinkRequestStore()
        requiredStore.requireAcknowledgedHandler()
        let requiredId = bufferedRequest(requiredStore.accept(requiredUrl))
        require(
            requiredStore.useLinking().isEmpty,
            "native initialization must not drain a URL reserved for the acknowledged handler"
        )
        let requiredReplay = requiredStore.useHandler()
        require(
            requiredReplay.count == 1 && requiredReplay[0].0 == requiredId,
            "a handler registered after Linking readiness must receive the reserved URL"
        )

        let reloadUrl = URL(string: "myapp://bridge-reload")!
        var reloadStore = CustomerIOReactNativeDeepLinkRequestStore()
        _ = reloadStore.useLinking()
        _ = reloadStore.useHandler()
        let oldReloadId = handlerRequest(reloadStore.accept(reloadUrl))
        let replacementIds = reloadStore.removeHandler()
        require(replacementIds.count == 1, "handler removal must rebuffer its in-flight URL")
        require(
            reloadStore.accept(linkingUrl) == .linking(linkingUrl),
            "handler removal must restore previously signalled Linking readiness"
        )
        let reloadReplay = reloadStore.useHandler()
        require(
            reloadReplay.count == 1 && reloadReplay[0].0 == replacementIds[0],
            "a replacement handler must receive the rebuffered URL"
        )
        require(
            reloadStore.acknowledge(oldReloadId, handled: true) == nil,
            "an acknowledgement from the invalidated bridge must not resolve the replacement"
        )
        require(
            reloadStore.acknowledge(replacementIds[0], handled: true) == .handled,
            "the replacement handler must resolve the rebuffered URL"
        )

        print("React Native deep-link request store tests passed")
    }
}
