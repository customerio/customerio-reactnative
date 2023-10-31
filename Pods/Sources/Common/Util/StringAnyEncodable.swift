import Foundation

public struct StringAnyEncodable: Encodable {
    private let logger: Logger
    private let data: [String: AnyEncodable]

    public init(logger: Logger, _ data: [String: Any]) {
        // Nested function to convert the ‘Any’ values to ‘AnyEncodable’ recursively
        func encode(value: Any) -> AnyEncodable? {
            switch value {
            case let enc as Encodable:
                return AnyEncodable(enc)

            case let dict as [String: Any]:
                return AnyEncodable(StringAnyEncodable(logger: logger, dict))

            case let list as [Any]:
                // If the value is an array, recursively encode each element
                return AnyEncodable(list.compactMap { encode(value: $0) })

            default:
                logger.error("Tried to convert \(data) into [String: AnyEncodable] but the data type is not Encodable.")
                return nil
            }
        }

        self.logger = logger
        self.data = data.compactMapValues { encode(value: $0) }
    }

    public func encode(to encoder: Encoder) throws {
        try data.encode(to: encoder)
    }
}
