import CioMessagingPush
import Foundation
import UIKit

/// Hands Customer.io silent pushes to the JavaScript handler and owns each push's completion
/// handler. iOS can launch the app for a push before JavaScript runs, so a push waits until
/// JavaScript registers its handler. It completes with `.newData` when JavaScript acknowledges it,
/// or `.noData` after 25 seconds, within the roughly 30 seconds iOS allows. Main thread only.
enum CustomerIOReactNativeBackgroundPushRouter {
    private struct PendingPush {
        let push: [String: Any]
        let completion: (UIBackgroundFetchResult) -> Void
        var sent = false
    }

    private static var pending: [String: PendingPush] = [:]
    private static weak var handler: NativeMessagingPush?

    private static let handlerSetKey = "io.customer.reactnative.backgroundPushHandlerSet"

    /// JavaScript set a handler in this launch or an earlier one.
    static var isHandlerExpected: Bool {
        handler != nil || UserDefaults.standard.bool(forKey: handlerSetKey)
    }

    static func accept(_ push: CustomerIOBackgroundPush, completion: @escaping (UIBackgroundFetchResult) -> Void) {
        let id = UUID().uuidString
        pending[id] = PendingPush(
            push: ["deliveryId": push.deliveryID, "deliveryToken": push.deliveryToken, "data": push.data],
            completion: completion
        )
        send(id)
        DispatchQueue.main.asyncAfter(deadline: .now() + 25) {
            // JavaScript never registered, so this version of the app no longer sets a handler.
            if pending[id]?.sent == false {
                UserDefaults.standard.removeObject(forKey: handlerSetKey)
            }
            complete(id, with: .noData)
        }
    }

    static func register(_ module: NativeMessagingPush) {
        handler = module
        UserDefaults.standard.set(true, forKey: handlerSetKey)
        pending.keys.forEach(send)
    }

    /// JavaScript removed its handler.
    static func unregister(_ module: NativeMessagingPush) {
        if handler === module {
            handler = nil
        }
        UserDefaults.standard.removeObject(forKey: handlerSetKey)
    }

    /// The React instance is going away, as on a reload; pushes it didn't finish go to the next one.
    static func release(_ module: NativeMessagingPush) {
        guard handler === module else { return }
        handler = nil
        for id in pending.keys {
            pending[id]?.sent = false
        }
    }

    static func acknowledge(_ id: String) {
        complete(id, with: .newData)
    }

    private static func send(_ id: String) {
        guard let handler, let entry = pending[id], !entry.sent else { return }
        pending[id]?.sent = true
        handler.emitBackgroundPush(["id": id, "push": entry.push])
    }

    private static func complete(_ id: String, with result: UIBackgroundFetchResult) {
        pending.removeValue(forKey: id)?.completion(result)
    }
}
