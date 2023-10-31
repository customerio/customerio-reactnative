import Foundation

/// Status of the Queue
public struct QueueStatus: Equatable {
    /// the identifier of the queue the task was added to
    let queueId: String
    /// the number of tasks in the queue that have not run successfully.
    /// This includes tasks that are currently running or have run in the past but failed.
    let numTasksInQueue: Int
}

// used for testing
extension QueueStatus {
    static var successAddingSingleTask: QueueStatus {
        QueueStatus(queueId: String.random, numTasksInQueue: 1)
    }
}
