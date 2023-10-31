import Foundation

// The types of events for push metrics.
public enum Metric: String, Codable {
    case delivered
    case opened
    case converted
}

public extension Metric {
    static func getEvent(from metricStr: String) -> Metric? {
        Metric(rawValue: metricStr.lowercased())
    }
}
