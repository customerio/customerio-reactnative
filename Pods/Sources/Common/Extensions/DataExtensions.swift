import Foundation

public extension Data {
    var string: String? {
        String(data: self, encoding: .utf8)
    }
}
