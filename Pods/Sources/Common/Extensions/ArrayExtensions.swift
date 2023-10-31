import Foundation

public extension Array {
    mutating func removeFirstOrNil() -> Element? {
        guard !isEmpty else {
            return nil
        }

        return removeFirst()
    }

    func mapNonNil<T>() -> [T] where Element == T? {
        filter { $0 != nil }.map { $0! }
    }
}
