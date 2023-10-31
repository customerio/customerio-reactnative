import Foundation

protocol QueueQueryRunner: AutoMockable {
    func getNextTask(_ queue: [QueueTaskMetadata], lastRanTask: QueueTaskMetadata?, lastFailedTask: QueueTaskMetadata?)
        -> QueueTaskMetadata?
    func reset()
}

// sourcery: InjectRegister = "QueueQueryRunner"
class CioQueueQueryRunner: QueueQueryRunner {
    var queryCriteria = QueueQueryCriteria()

    private let logger: Logger

    init(logger: Logger) {
        self.logger = logger
    }

    func getNextTask(
        _ inventory: [QueueTaskMetadata],
        lastRanTask: QueueTaskMetadata?,
        lastFailedTask: QueueTaskMetadata?
    ) -> QueueTaskMetadata? {
        guard !inventory.isEmpty else {
            return nil
        }
        let inventory = getInventoryTasksLeftToRun(inventory: inventory, lastRanTask: lastRanTask)
        if let lastFailedTask = lastFailedTask {
            updateCriteria(lastFailedTask: lastFailedTask)
        }

        // log *after* updating the criteria
        logger.debug("queue querying next task. criteria: \(queryCriteria)")

        return inventory.first(where: { doesTaskPassCriteria($0) })
    }

    func reset() {
        logger.debug("resetting queue tasks query criteria")

        queryCriteria.reset()
    }

    func getInventoryTasksLeftToRun(
        inventory: [QueueTaskMetadata],
        lastRanTask: QueueTaskMetadata?
    ) -> [QueueTaskMetadata] {
        guard let lastRanTask = lastRanTask else {
            return inventory
        }

        guard let indexOfLastRanTask = inventory.firstIndex(of: lastRanTask) else {
            return inventory
        }

        return Array(inventory.suffix(from: indexOfLastRanTask + 1))
    }

    func updateCriteria(lastFailedTask: QueueTaskMetadata) {
        if let groupToExclude = lastFailedTask.groupStart {
            queryCriteria.excludeGroups.insert(groupToExclude)
        }
    }

    private func doesTaskPassCriteria(_ task: QueueTaskMetadata) -> Bool {
        var didPassCriteria = true

        if let groupsTaskBelongsTo = task.groupMember {
            queryCriteria.excludeGroups.forEach { groupToExclude in
                if groupsTaskBelongsTo.contains(groupToExclude) {
                    didPassCriteria = false
                }
            }
        }

        return didPassCriteria
    }
}

struct QueueQueryCriteria {
    var excludeGroups: Set<String> = Set()

    mutating func reset() {
        excludeGroups.removeAll()
    }
}
