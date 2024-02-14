import CioInternalCommon
import Foundation

protocol PushHistory: AutoMockable {
    /**
     Thread-safe method to check if a push event has been handled before.

     If the push has not been handled before, it will be marked as handled. This is to prevent race conditions. Code such as this may have a race condition bug that we want to prevent:

     ```
     let hasPushBeenHandled = pushHistory.hasHandledPush(pushId)
     if !hasPushBeenHandled {
       pushHistory.markPushAsHandled(pushId)
     }
     ```
     By having 1 thread-safe function perform the check and mark, we can prevent this scenario.

     @return true if push has been handled before. false otherwise.
     */
    func hasHandledPush(pushEvent: PushHistoryEvent, pushId: String, pushDeliveryDate: Date) -> Bool
}

enum PushHistoryEvent {
    case didReceive
    case willPresent
}

/*
 Thread-safe store of push notifications that have been handled by the SDK. Used to prevent possible duplication of handling of events.

 Singleton because this is an in-memory store.
 */
// sourcery: InjectRegister = "PushHistory"
// sourcery: InjectSingleton
class PushHistoryImpl: PushHistory {
    private let lock: Lock

    @Atomic private var history: [PushHistoryEvent: Set<Push>] = [:]

    init(lockManager: LockManager) {
        self.lock = lockManager.getLock(id: .pushHistory)
    }

    func hasHandledPush(pushEvent: PushHistoryEvent, pushId: String, pushDeliveryDate: Date) -> Bool {
        lock.lock()
        defer { lock.unlock() }

        var eventsHistory = history[pushEvent] ?? Set<Push>()

        let push = Push(pushId: pushId, pushDeliveryDate: pushDeliveryDate)
        let hasHandledAlready = eventsHistory.contains(push)

        if hasHandledAlready {
            return true // push has already been handled. exit early
        }

        eventsHistory.insert(push)

        history[pushEvent] = eventsHistory

        return false // push has not yet been handled.
    }

    // In order to uniquely identify a push notification from another, the identifier is not enough. For local notifications especially,
    // it's possible that 2+ push notifications will have the same identifier. This is why we also include the date that the push was displayed.
    private struct Push: Hashable {
        let pushId: String
        let pushDeliveryDate: Date
    }
}
