import Foundation

// Get an instance of a `Lock`.
//
// It's important that `Lock` instances are shared across instances of objects
// needing the same lock.
// Instead of making every class that contains a `Lock` a singleton, let's make
// all `Lock` instances singletons.
//
// sourcery: InjectRegister = "LockManager"
// sourcery: InjectSingleton
public class LockManager {
    private var locks: [String: Lock] = [:]

    private let lock = Lock.unsafeInit()

    public func getLock(id: LockReference) -> Lock {
        lock.lock()
        defer { lock.unlock() }

        if let exitingLock = locks[id.rawValue] {
            return exitingLock
        }

        let newLock = Lock.unsafeInit()
        locks[id.rawValue] = newLock

        return newLock
    }
}

public enum LockReference: String {
    case queueStorage
    case singleScheduleTimer
}
