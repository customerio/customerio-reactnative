import Foundation

/// https://customer.io/docs/api/#operation/track
struct TrackRequestBody<T: Encodable>: Encodable {
    let type: EventType
    let name: String
    let data: T
    let timestamp: Date?
}

enum EventType: String, Codable {
    case event
    case screen
}
