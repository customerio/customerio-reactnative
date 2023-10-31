import Foundation

public class EngineRoute {
    public let route: String
    var properties = [String: AnyEncodable]()

    public init(route: String) {
        self.route = route
    }

    public func addProperty(key: String, value: Any) {
        properties[key] = AnyEncodable(value)
    }
}
