import Foundation

internal extension StringProtocol {
    // Uppercase the first character without modifying the rest of the string.
    // "notDeteremined" -> "NotDetermined"
    // "notdetermined" -> "Notdeteremined"
    // "not determined" -> "Not determined"
    var firstUppercased: String { return prefix(1).uppercased() + dropFirst() }
}
