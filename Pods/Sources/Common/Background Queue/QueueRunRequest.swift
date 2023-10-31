import Foundation

public protocol QueueRunRequest: AutoMockable {
    func start(onComplete: @escaping () -> Void)
}

// Logic of the queue data structure. Queries for tasks to run and executes each task one-by-one.
// sourcery: InjectRegister = "QueueRunRequest"
public class CioQueueRunRequest: QueueRunRequest {
    private let runner: QueueRunner
    private let storage: QueueStorage
    private let requestManager: QueueRequestManager
    private let logger: Logger
    private let queryRunner: QueueQueryRunner
    private let threadUtil: ThreadUtil

    private let shortTaskId: (String) -> String = { $0[0 ..< 5] }

    init(
        runner: QueueRunner,
        storage: QueueStorage,
        requestManager: QueueRequestManager,
        logger: Logger,
        queryRunner: QueueQueryRunner,
        threadUtil: ThreadUtil
    ) {
        self.runner = runner
        self.storage = storage
        self.requestManager = requestManager
        self.logger = logger
        self.queryRunner = queryRunner
        self.threadUtil = threadUtil
    }

    public func start(onComplete: @escaping () -> Void) {
        let isRequestCurrentlyRunning = requestManager.startRequest(onComplete: onComplete)

        if !isRequestCurrentlyRunning {
            startNewRequestRun()
        }
    }

    private func startNewRequestRun() {
        threadUtil.runBackground {
            self.runTasks()
        }
    }

    // Disable swiftlint because function at this time isn't too complex to need to make it smaller.
    // Many of the lines of this function are logging related.
    // swiftlint:disable:next function_body_length
    func runTasks() {
        // Variables that power the logic of the queue run loop
        var lastRanTask: QueueTaskMetadata?
        var lastFailedTask: QueueTaskMetadata?
        var continueRunnning = true
        let whileLoopWait = DispatchGroup() // make async operations perform synchronously in while loop

        // call when you're done with task
        func updateWhileLoopLogicVariables(didTaskFail: Bool, taskJustExecuted: QueueTaskMetadata) {
            lastFailedTask = didTaskFail ? taskJustExecuted : nil
            lastRanTask = taskJustExecuted
        }

        func doneRunning() {
            continueRunnning = false
            logger.debug("queue out of tasks to run.")

            queryRunner.reset()

            return requestManager.requestComplete()
        }

        // The queue runs a continuous loop until it has determined that it has reached the end of the queue and has processed all the tasks that it can at this time.
        while continueRunnning {
            // get the inventory before running each task. If a task was added to the queue while the last task was being
            // executed, we can assert that new task will execute during this run.
            let queueInventory = storage.getInventory()

            guard let nextTaskToRunInventoryItem = queryRunner.getNextTask(
                queueInventory,
                lastRanTask: lastRanTask,
                lastFailedTask: lastFailedTask
            )
            else {
                // we hit the end of the current inventory. Done!
                doneRunning()
                break
            }

            let nextTaskStorageId = nextTaskToRunInventoryItem.taskPersistedId
            guard let nextTaskToRun = storage.get(storageId: nextTaskStorageId) else {
                // log error. this scenario shouldn't happen where task can't be found.
                logger.error("Tried to get queue task with storage id: \(nextTaskStorageId), but storage couldn't find it.")

                // The task failed to execute like a HTTP failure. Update `lastFailedTask`.
                updateWhileLoopLogicVariables(didTaskFail: true, taskJustExecuted: nextTaskToRunInventoryItem)
                continue // quit loop early and move to next task.
            }

            logger.debug("queue tasks left to run: \(queueInventory.count)")
            logger.debug("""
            queue next task to run: \(shortTaskId(nextTaskStorageId)),
            \(nextTaskToRun.type), \(nextTaskToRun.data.string ?? ""), \(nextTaskToRun.runResults)
            """)

            whileLoopWait.enter() // Call right before the async operation begins.
            // we are not using [weak self] because if the task is currently running,
            // we dont want the result handler to get garbage collected which could
            // make the task run again when it shouldn't.
            //
            // if we wanted to use [weak self] then we should allow running a task to cancel
            // while executing which would then allow this to use [weak self].
            runner.runTask(nextTaskToRun) { result in
                switch result {
                case .success:
                    self.logger.debug("queue task \(self.shortTaskId(nextTaskStorageId)) ran successfully")

                    self.logger.debug("queue deleting task \(self.shortTaskId(nextTaskStorageId))")
                    _ = self.storage.delete(storageId: nextTaskToRunInventoryItem.taskPersistedId)

                    updateWhileLoopLogicVariables(didTaskFail: false, taskJustExecuted: nextTaskToRunInventoryItem)
                case .failure(let error):
                    self.logger
                        .debug("queue task \(self.shortTaskId(nextTaskStorageId)) run failed \(error.localizedDescription)")

                    let previousRunResults = nextTaskToRun.runResults

                    // When a HTTP request isn't made, dont update the run history to give us inaccurate data.
                    if case .requestsPaused = error {
                        self.logger.debug("""
                        queue task \(self.shortTaskId(nextTaskStorageId)) didn't run because all HTTP requests paused.
                        """)

                        self.logger.info("queue is quitting early because all HTTP requests are paused.")

                        doneRunning()
                    } else if case .badRequest400 = error {
                        self.logger.error("Received HTTP 400 response while trying to \(nextTaskToRun.type). 400 responses never succeed and therefore, the SDK is deleting this SDK request and not retry. Error message from API: \(error.localizedDescription), request data sent: \(nextTaskToRun.data)")

                        _ = self.storage.delete(storageId: nextTaskToRunInventoryItem.taskPersistedId)

                        updateWhileLoopLogicVariables(didTaskFail: true, taskJustExecuted: nextTaskToRunInventoryItem)
                    } else {
                        let newRunResults = previousRunResults.totalRunsSet(previousRunResults.totalRuns + 1)

                        self.logger.debug("""
                        queue task \(self.shortTaskId(nextTaskStorageId)) updating run history
                        from: \(nextTaskToRun.runResults) to: \(newRunResults)
                        """)

                        _ = self.storage.update(
                            storageId: nextTaskToRunInventoryItem.taskPersistedId,
                            runResults: newRunResults
                        )
                        updateWhileLoopLogicVariables(didTaskFail: true, taskJustExecuted: nextTaskToRunInventoryItem)
                    }
                }

                // make sure to update the variables for the while loop logic before running the while loop again.
                whileLoopWait.leave()
            }

            // wait to end the while loop until the async operation has completed.
            whileLoopWait.wait()
        }
    }
}
