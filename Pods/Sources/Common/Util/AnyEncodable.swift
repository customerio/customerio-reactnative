import Foundation

///
public struct AnyEncodable: Encodable {
    public let value: Encodable

    public init(_ encodable: Encodable) {
        self.value = encodable
    }

    public func encode(to encoder: Encoder) throws {
        try value.encode(to: encoder)
    }
}
