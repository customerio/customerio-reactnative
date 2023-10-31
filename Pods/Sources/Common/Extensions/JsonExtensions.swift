import Foundation

extension JSONEncoder {
    var secondsSince1970NoDecimal: DateEncodingStrategy {
        .custom { date, encoder in
            var container = encoder.singleValueContainer()
            let seconds = Int(date.timeIntervalSince1970)
            try container.encode(seconds)
        }
    }
}
