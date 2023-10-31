import Foundation

/**
 Simple singleton that helps assert that the background queue is only running
 one run request at one time (1 run request per site id since each site id can have it's own background queue).

 When the background queue wants to run it's tasks, it's important that the queue only have 1 concurrent runner
 running at one time to prevent race conditions and tasks running multiple times.

 This class is small and separate from the rest of the queue logic for some readability/scalability value but
 mostly memory safety.

 We want to avoid making our queue classes singletons because these classes may have lots of
 dependencies inside of them (especially the runner). We want to avoid keeping all of these dependencies sitting in
 memory.
 */
public protocol QueueRequestManager: AutoMockable {
    /// call when a runner run request is complete
    func requestComplete()
    /// call when a new run request is requested. adds callback to list of callbacks
    /// to call when run request is done running.
    /// returns is an existing run request is currently running or not.
    func startRequest(onComplete: @escaping () -> Void) -> Bool
}

// sourcery: InjectRegister = "QueueRequestManager"
// sourcery: InjectSingleton
public class CioQueueRequestManager: QueueRequestManager {
    @Atomic var isRunningRequest = false
    @Atomic var callbacks: [() -> Void] = []

    public func requestComplete() {
        let existingCallbacks = callbacks

        callbacks = []
        isRunningRequest = false

        existingCallbacks.forEach { callback in
            callback()
        }
    }

    public func startRequest(onComplete: @escaping () -> Void) -> Bool {
        let isQueueRunningARequest = isRunningRequest

        callbacks.append(onComplete)

        if !isQueueRunningARequest {
            isRunningRequest = true
        }

        // return the isRunningRequest value before modification or we will
        // *always* return true (since we modify to true or ignore)
        return isQueueRunningARequest
    }
}
