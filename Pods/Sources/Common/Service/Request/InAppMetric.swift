import Foundation

// The types of events for push metrics.
public enum InAppMetric: String, Codable {
    case opened
    case clicked

    enum CodingKeys: String, CodingKey {
        case opened
        case clicked
    }
}
