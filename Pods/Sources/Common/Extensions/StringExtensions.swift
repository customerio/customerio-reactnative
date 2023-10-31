import Foundation

public extension String {
    init(apnDeviceToken: Data) {
        /// Convert `Data` to `String` for APN device token.
        /// [Reference](https://nshipster.com/apns-device-tokens/)
        self = apnDeviceToken.map { String(format: "%02x", $0) }.joined()
    }

    var data: Data! {
        data(using: .utf8)
    }

    var url: URL? {
        URL(string: self)
    }

    static var abcLetters: String {
        "abcdefghijklmnopqrstuvwxyz"
    }

    func getFirstNCharacters(_ numberOfCharacters: Int) -> String {
        self[0 ..< numberOfCharacters]
    }

    static var random: String {
        String.random()
    }

    static func random(length: Int = 10) -> String {
        String((0 ..< length).map { _ in abcLetters.randomElement()! })
    }

    /**
     Checks if the string matches the regex pattern.

     Will only return true if the *full string* is matched, not a substring.
     */
    func matches(regex: String) -> Bool {
        // Force try because we are assuming that all regex patterns are hard-coded into
        // the source code and therefore can be tested with an automated test.
        // swiftlint:disable:next force_try
        let regex = try! NSRegularExpression(pattern: regex, options: [])

        let range = NSRange(location: 0, length: utf16.count)
        let match = regex.firstMatch(in: self, options: [], range: range)

        // By checking the ranges equal, we are asserting that the regex didn't just match
        // a subset of the string meaning it may not match the whole string.
        return match != nil && match?.range == range
    }

    /// Given: "foo" and input ".jpg", return "foo.jpg"
    /// Given: "foo.jpg" and input ".jpg", return "foo.jpg" (unmodified)
    func setLastCharacters(_ characters: String) -> String {
        if hasSuffix(characters) { return self }

        return self + characters
    }

    func isBlankOrEmpty() -> Bool {
        trimmingCharacters(in: .whitespaces).isEmpty
    }

    /// Substrings
    /// let s = "hello"
    /// s[0..<3] // "hel"
    /// s[3...]  // "lo"
    subscript(_ range: CountableRange<Int>) -> String {
        let start = index(startIndex, offsetBy: max(0, range.lowerBound))
        let end = index(start, offsetBy: min(
            count - range.lowerBound,
            range.upperBound - range.lowerBound
        ))
        return String(self[start ..< end])
    }

    subscript(_ range: CountablePartialRangeFrom<Int>) -> String {
        let start = index(startIndex, offsetBy: max(0, range.lowerBound))
        return String(self[start...])
    }
}
