import Foundation

public extension Dictionary where Key == String, Value == Any {
    func mergeWith(_ other: [String: Any]) -> [String: Any] {
        merging(other) { $1 }
    }
}
