import Foundation

internal extension StringProtocol {
    var firstUppercased: String { return prefix(1).uppercased() + dropFirst() }
}