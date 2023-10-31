import Foundation

/// Mutex/lock implementation
public class Lock {
    // Resursive lock allows a thread to call lock() N times
    // and will not release the lock until unlock() called N times, too.
    // This makes the lock safe for use cases such as recursion and
    // calling other methods in a class that acquire the lock.
    private let _lock = NSRecursiveLock()

    // It's recommended to use `LockManager` to get an instance of a `Lock`.
    // Use this function only if your use case requires so.
    public static func unsafeInit() -> Lock {
        Lock()
    }

    private init() {}

    func lock() {
        _lock.lock()
    }

    func unlock() {
        _lock.unlock()
    }
}
