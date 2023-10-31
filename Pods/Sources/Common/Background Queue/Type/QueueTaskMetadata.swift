import Foundation

/// Pointer to full queue task in persistent storage.
/// This data structure is meant to be as small as possible with the
/// ability to hold all queue task metadata in memory at runtime.
public struct QueueTaskMetadata: Codable, Equatable, Hashable, AutoLenses {
    let taskPersistedId: String
    let taskType: String
    /// The start of a new group of tasks.
    /// Tasks can be the start of of 0 or 1 groups
    let groupStart: String?
    /// Groups that this task belongs to.
    /// Tasks can belong to 0+ groups
    let groupMember: [String]?
    /// Populated when the task is added to the queue.
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case taskPersistedId = "task_persisted_id"
        case taskType = "task_type"
        case groupStart = "group_start"
        case groupMember = "group_member"
        case createdAt = "created_at"
    }
}

extension QueueTaskMetadata {
    static var random: QueueTaskMetadata {
        QueueTaskMetadata(
            taskPersistedId: String.random,
            taskType: String.random,
            groupStart: nil,
            groupMember: nil,
            createdAt: Date.nowNoMilliseconds
        )
    }
}
