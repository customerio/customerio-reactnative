import Foundation

public struct QueueTaskRunResults: Codable, AutoLenses, Equatable {
    let totalRuns: Int

    enum CodingKeys: String, CodingKey {
        case totalRuns = "total_runs"
    }
}
