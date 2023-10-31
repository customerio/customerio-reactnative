import Foundation

// Standard device structure
public struct Device<T: Encodable>: Encodable {
    public let token: String
    public let platform: String // iOS, tvOS, watchOS, etc.
    public let lastUsed: Date
    public let attributes: T?

    public init(token: String, platform: String, lastUsed: Date, attributes: T?) {
        self.token = token
        self.platform = platform
        self.lastUsed = lastUsed
        self.attributes = attributes
    }

    enum CodingKeys: String, CodingKey {
        case platform
        case token = "id"
        case lastUsed = "last_used"
        case attributes
    }
}
