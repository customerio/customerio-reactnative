import Foundation

/**
 One source of truth get/set data for the background queue. Queue tasks inventory + tasks.

 The background queue data consists of:
 1. background queue tasks - data required to execute a background queue task
 2. The queue (aka: inventory) defining the ordered list of tasks to be executed.

 All data is persisted to the device file system.

 The queue tasks are stored as .json files (since json is easy to construct in swift)
 where each queue task is an individual file.

 The queue inventory is one .json file of a JSON array ordered from first to last task to run.

 Each queue inventory item, `QueueTaskMetadata`, points to a queue task, `QueueTask`.

 Yes, we could have the queue inventory (JSON array) contain all of the queue task data in it instead
 of having the queue inventory separated in the file system from the queue tasks themselves.
 We keep them separate to keep the inventory as small as possible so we don't need to worry about
 keeping the whole queue inventory in memory. Being a SDK, our memory footprint is important to stay
 as small as possible without concern. The inventory could get into hundreds or thousands of tasks
 if a customer app creates lots of tasks for an app that is in Airplane mode, for example.
 */
public protocol QueueStorage: AutoMockable {
    func getInventory() -> [QueueTaskMetadata]
    func saveInventory(_ inventory: [QueueTaskMetadata]) -> Bool

    func create(type: String, data: Data, groupStart: QueueTaskGroup?, blockingGroups: [QueueTaskGroup]?)
        -> CreateQueueStorageTaskResult
    func update(storageId: String, runResults: QueueTaskRunResults) -> Bool
    func get(storageId: String) -> QueueTask?
    func delete(storageId: String) -> Bool
    func deleteExpired() -> [QueueTaskMetadata]
}

// sourcery: InjectRegister = "QueueStorage"
public class FileManagerQueueStorage: QueueStorage {
    private let fileStorage: FileStorage
    private let jsonAdapter: JsonAdapter
    private let siteId: String
    private let sdkConfig: SdkConfig
    private let logger: Logger
    private let dateUtil: DateUtil
    private var inventoryStore: QueueInventoryMemoryStore

    private let lock: Lock

    private var inventory: [QueueTaskMetadata]? {
        get {
            lock.lock()
            defer { lock.unlock() }

            if let inventoryCache = inventoryStore.inventory {
                return inventoryCache
            }

            guard let data = fileStorage.get(type: .queueInventory, fileId: nil) else { return nil }
            guard let readInventory: [QueueTaskMetadata] = jsonAdapter.fromJson(data) else { return nil }
            inventoryStore.inventory = readInventory // set in-memory cache for next time getter is called

            return readInventory
        }
        set {
            lock.lock()
            defer { lock.unlock() }

            guard let data = jsonAdapter.toJson(newValue) else {
                return
            }

            // the inventory is the BQ's single source of truth for what tasks are in the BQ. It's important that the inventory cache reflects what's in SDK storage so only update
            // it after we successfully save the storage.
            // If there is a failed save to file system, the item added to the BQ will get ignored to try and keep the SDK into an error-free state.
            let successfullySavedInStorage = fileStorage.save(type: .queueInventory, contents: data, fileId: nil)

            if successfullySavedInStorage {
                inventoryStore.inventory = newValue // update cache
            }
        }
    }

    init(
        fileStorage: FileStorage,
        jsonAdapter: JsonAdapter,
        lockManager: LockManager,
        sdkConfig: SdkConfig,
        logger: Logger,
        dateUtil: DateUtil,
        inventoryStore: QueueInventoryMemoryStore
    ) {
        self.siteId = sdkConfig.siteId
        self.fileStorage = fileStorage
        self.jsonAdapter = jsonAdapter
        self.sdkConfig = sdkConfig
        self.logger = logger
        self.dateUtil = dateUtil
        self.lock = lockManager.getLock(id: .queueStorage)
        self.inventoryStore = inventoryStore
    }

    public func getInventory() -> [QueueTaskMetadata] {
        inventory ?? []
    }

    public func saveInventory(_ inventory: [QueueTaskMetadata]) -> Bool {
        // Logic of saving inventory was moved into the `inventory` setter.
        // However, to keep backwards compatibility with the API of this function (returning a Bool),
        // we have this below logic to check if the inventory was successfully saved.
        let inventoryBeforeSave = getInventory() // getInventory reads from the in-memory cache so they are performant to perform.
        self.inventory = inventory
        let inventoryAfterSave = getInventory()

        let inventorySavedSuccessfully = inventoryBeforeSave != inventoryAfterSave

        return inventorySavedSuccessfully
    }

    public func create(
        type: String,
        data: Data,
        groupStart: QueueTaskGroup?,
        blockingGroups: [QueueTaskGroup]?
    ) -> CreateQueueStorageTaskResult {
        lock.lock()
        defer { lock.unlock() }

        var existingInventory = getInventory()
        let beforeCreateQueueStatus = QueueStatus(queueId: siteId, numTasksInQueue: existingInventory.count)

        let newTaskStorageId = UUID().uuidString
        let newQueueTask = QueueTask(
            storageId: newTaskStorageId,
            type: type,
            data: data,
            runResults: QueueTaskRunResults(totalRuns: 0)
        )

        if !update(queueTask: newQueueTask) {
            return CreateQueueStorageTaskResult(success: false, queueStatus: beforeCreateQueueStatus, createdTask: nil)
        }

        let newQueueItem = QueueTaskMetadata(
            taskPersistedId: newTaskStorageId,
            taskType: type,
            groupStart: groupStart?.string,
            groupMember: blockingGroups?.map(\.string),
            createdAt: dateUtil.now
        )
        existingInventory.append(newQueueItem)

        let updatedInventoryCount = existingInventory.count
        let afterCreateQueueStatus = QueueStatus(queueId: siteId, numTasksInQueue: updatedInventoryCount)

        if !saveInventory(existingInventory) {
            return CreateQueueStorageTaskResult(success: false, queueStatus: beforeCreateQueueStatus, createdTask: nil)
        }

        // It's more accurate for us to get the inventory item from the inventory instead of just returning
        // newQueueItem. This is because queue storage when saving to storage might modify the metadata object
        // such as removing milliseconds from Date. By getting the inventory item directly from device storage,
        // we return the most accurate data on the inventory item.
        guard let createdTask = getInventory().first(where: { $0.taskPersistedId == newQueueItem.taskPersistedId })
        else {
            logger.error("expected to find task \(newQueueItem) to be in the inventory but it wasn't")
            return CreateQueueStorageTaskResult(success: false, queueStatus: beforeCreateQueueStatus, createdTask: nil)
        }

        return CreateQueueStorageTaskResult(
            success: true,
            queueStatus: afterCreateQueueStatus,
            createdTask: createdTask
        )
    }

    public func update(storageId: String, runResults: QueueTaskRunResults) -> Bool {
        lock.lock()
        defer { lock.unlock() }

        guard var existingQueueTask = get(storageId: storageId) else {
            return false
        }

        existingQueueTask = existingQueueTask.runResultsSet(runResults)

        return update(queueTask: existingQueueTask)
    }

    public func get(storageId: String) -> QueueTask? {
        lock.lock()
        defer { lock.unlock() }

        guard let data = fileStorage.get(type: .queueTask, fileId: storageId),
              let task: QueueTask = jsonAdapter.fromJson(data)
        else {
            return nil
        }

        return task
    }

    public func delete(storageId: String) -> Bool {
        lock.lock()
        defer { lock.unlock() }

        // update inventory first so code that requests the inventory doesn't get the inventory item we are deleting
        var existingInventory = getInventory()
        existingInventory.removeAll { $0.taskPersistedId == storageId }
        let updateInventoryResult = saveInventory(existingInventory)

        if !updateInventoryResult { return false }

        // if this fails, we at least deleted the task from inventory so
        // it will not run again which is the most important thing
        return fileStorage.delete(type: .queueTask, fileId: storageId)
    }

    public func deleteExpired() -> [QueueTaskMetadata] {
        lock.lock()
        defer { lock.unlock() }

        logger.debug("deleting expired tasks from the queue")

        var tasksToDelete: Set<QueueTaskMetadata> = Set()
        let queueTaskExpiredThreshold = Date().subtract(sdkConfig.backgroundQueueExpiredSeconds, .second)
        logger.debug("""
        deleting tasks older then \(queueTaskExpiredThreshold.string(format: .iso8601noMilliseconds)),
        current time is: \(Date().string(format: .iso8601noMilliseconds))
        """)

        getInventory().filter { inventoryItem in
            // Do not delete tasks that are at the start of a group of tasks.
            // Why? Take for example Identifying a profile. If we identify profile X in an app today,
            // we expire the Identify queue task and delete the queue task, and then profile X stays logged
            // into an app for 6 months, that means we run the risk of 6 months of data never successfully being sent
            // to the API.
            // Also, queue tasks such as Identifying a profile are more rare queue tasks compared to tracking of events
            // (that are not the start of a group). So, it should rarely be a scenario when there are thousands
            // of "expired" Identifying a profile tasks sitting in a queue. It's the queue tasks such as tracking
            // that are taking up a large majority of the queue inventory. Those we should be deleting more of.
            inventoryItem.groupStart == nil
        }.forEach { taskInventoryItem in
            let isItemTooOld = taskInventoryItem.createdAt.isOlderThan(queueTaskExpiredThreshold)

            if isItemTooOld {
                tasksToDelete.insert(taskInventoryItem)
            }
        }

        logger.debug("deleting \(tasksToDelete.count) tasks. \n Tasks: \(tasksToDelete)")

        tasksToDelete.forEach { taskToDelete in
            // Because the queue tasks we are deleting are not the start of a group,
            // if deleting a task is not successful, we can ignore that
            // because it doesn't negatively effect the state of the SDK or the queue.
            _ = self.delete(storageId: taskToDelete.taskPersistedId)
        }

        return Array(tasksToDelete)
    }
}

public extension FileManagerQueueStorage {
    private func update(queueTask: QueueTask) -> Bool {
        guard let data = jsonAdapter.toJson(queueTask) else {
            return false
        }

        return fileStorage.save(type: .queueTask, contents: data, fileId: queueTask.storageId)
    }
}

public struct CreateQueueStorageTaskResult {
    public let success: Bool
    public let queueStatus: QueueStatus
    public let createdTask: QueueTaskMetadata?
}
