import Foundation

// Represents number of seconds.
// let oneSecond: Seconds = 1
// let halfOfOneSecond: Seconds = 0.5 // 500 milliseconds
public typealias Seconds = TimeInterval

public extension Seconds {
    static func secondsFromDays(_ numberOfDays: Int) -> Seconds {
        let secondsIn24Hours = 86400

        return Seconds(secondsIn24Hours * numberOfDays)
    }
}
