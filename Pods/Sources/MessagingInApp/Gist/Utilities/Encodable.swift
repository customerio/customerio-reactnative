import Foundation

extension Encodable {
    func asDictionary() throws -> [String: Any] {
        let data = try JSONEncoder().encode(self)
        guard let dictionary =
            try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any]
        else {
            // swiftlint:disable discouraged_direct_init
            throw NSError()
            // swiftlint:enable discouraged_direct_init
        }
        return dictionary
    }
}
