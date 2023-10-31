import Foundation

/// Wrapper for `Timer` with a simple API and ability to mock it to make tests run faster then
/// having to wait for a Timer to end.
protocol SimpleTimer: AutoMockable {
    func scheduleAndCancelPrevious(seconds: Seconds, block: @escaping () -> Void)
    func scheduleIfNotAlready(seconds: Seconds, block: @escaping () -> Void) -> Bool
    func cancel()
}

// sourcery: InjectRegister = "SimpleTimer"
class CioSimpleTimer: SimpleTimer {
    // Because timer operations are asynchronous (DispatchQueue.main.async), this property
    // synchronously keeps track of the status of the timer operations (schedule, cancel)
    @Atomic private var timerAlreadyScheduled = false
    private let lock = Lock.unsafeInit() // each SimpleTimer instance should have it's own Lock.
    private var timer: Timer?
    private let logger: Logger
    private let instanceIdentifier = String.random

    init(logger: Logger) {
        self.logger = logger
    }

    deinit {
        unsafeCancel()
    }

    func scheduleAndCancelPrevious(seconds: Seconds, block: @escaping () -> Void) {
        lock.lock()
        defer { lock.unlock() }

        // Was having issues where timer would schedule but not execute `block` lambda.
        // Scheduling timer on main queue was suggested as the fix.
        // https://stackoverflow.com/a/50843382
        DispatchQueue.main.async {
            self.unsafeCancel() // cancel previous timer if one exists

            self.log("making a timer for \(seconds) seconds.")

            self.timer = Timer.scheduledTimer(withTimeInterval: seconds, repeats: false, block: { _ in
                self.timerAlreadyScheduled = false
                self.timer = nil

                self.log("timer is done! It's been reset.")

                block()
            })
        }
    }

    func scheduleIfNotAlready(seconds: Seconds, block: @escaping () -> Void) -> Bool {
        lock.lock()
        defer { lock.unlock() }

        if timerAlreadyScheduled {
            log("already scheduled to run. Skipping request.")
            return false
        }

        timerAlreadyScheduled = true

        scheduleAndCancelPrevious(seconds: seconds, block: block)

        return true
    }

    func cancel() {
        lock.lock()
        defer { lock.unlock() }

        timerAlreadyScheduled = false

        // because we are scheduling the timer on the main queue,
        // we need to cancel it on the queue to avoid a race condition.
        DispatchQueue.main.async {
            self.log("timer is being cancelled")

            self.unsafeCancel()
        }
    }

    private func unsafeCancel() {
        timer?.invalidate()
        timer = nil
    }

    private func log(_ message: String) {
        logger.debug("Timer (\(instanceIdentifier)) \(message)")
    }
}
