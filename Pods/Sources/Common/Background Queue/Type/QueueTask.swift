import Foundation

/**
 Full task for the background queue.
 Task is persisted in storage on device to run the task in the future.

 `data` is custom data that is unique to each queue task.
 It's recommended you create a struct containing all data that is needed in order
 to run the queue task and encode the struct to `Data` using `JsonAdapter`.

 This is easy except for the scenario where we allow generic `Encodable` data
 to be provided to the SDK such as tracking events or identifying a customer.
 The SDK allows `Encodable` data to be passed in for custom attributes. The problem
 with that is we need the data to be `Encodable` *and* `Decodable` (`QueueTask` is
 `Codable`). The way to get around this is by converting the `Encodable` data
 into a `Codable` data structure. `String` is an easy one. So, here is an
 example of accepting `Encodable` data and turning it into a `QueueTask`:
 ```swift
 struct IdentifyProfileQueueTaskData: Codable {
   let identifier: String
   /// JSON string: '{"foo": "bar"}'
   let attributesJsonString: String?
 }

 public func identify<RequestBody: Encodable>(
   identifier: String,
   body: RequestBody
 ) {
   let jsonBodyString = jsonAdapter.toJsonString(body)

   let queueTaskData = IdentifyProfileQueueTaskData(identifier: identifier,
     attributesJsonString: jsonBodyString)
   let queueStatus = backgroundQueue.addTask(type: .identifyProfile, data: queueTaskData)
 }

 // Then, when we perform the HTTP request in the background queue, use Data
 HttpRequestParams(endpoint: .identifyCustomer(identifier: taskData.identifier),
 headers: nil, body: taskData.attributesJsonString?.data)
 ```
 */
public struct QueueTask: Codable, AutoLenses, Equatable {
    /// ID used to store the task in persistant storage
    public let storageId: String
    /// the type of task. used when running tasks
    public let type: String
    /// data required to run the task
    public let data: Data
    /// the current run results of the task. keeping track of the history of the task
    public let runResults: QueueTaskRunResults

    enum CodingKeys: String, CodingKey {
        case storageId = "storage_id"
        case type
        case data
        case runResults = "run_results"
    }
}

extension QueueTask {
    static var random: QueueTask {
        QueueTask(
            storageId: String.random,
            type: String.random,
            data: Data(),
            runResults: QueueTaskRunResults(totalRuns: 1)
        )
    }
}
