import Foundation

/*
 Convert between Swift structs and JSON strings and vice-versa.

 Note: When writing tests to check that JSON is equal to other JSON, you need to
 compare the 2 by it's decoded Object, not `Data` or `String` value of the JSON.
 ```
 let expectedJsonBody = jsonAdapter.toJson(expectedObject)

 /// this will fail because the JSON keys sort order is random, not sorted.
 XCAssertEqual(expectedJsonBody, actualJsonBody)
 ```
 An easy fix for this is set `outputFormatting = .sortedKeys` on `JSONEncoder` but
 that is only available >= iOS 11. I don't like having tests that pass or fail depending
 on what iOS version we are testing against so having our CI tests only run on >= iOS 11
 is not a good solution there.

 Instead, you will just need to transition your JSON back into an object and compare
 the objects:
 ```
 let expectedObject: Foo = ...
 let actualObject: Foo = jsonAdapter.fromJson(jsonData!)!

 /// this compared values of the objects so it will pass.
 XCAssertEqual(expectedObject, actualObject)
 ```
 */
// sourcery: InjectRegister = "JsonAdapter"
public class JsonAdapter {
    var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        return decoder
    }

    var encoder: JSONEncoder {
        let encoder = JSONEncoder()
        // Do not modify the casing of JSON keys. It modifies custom attributes that customers give us.
        // Instead, add `CodingKeys` to your `Codable/Encodable` struct that JsonAdapter serializes to json.
        // encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder
            .outputFormatting =
            .sortedKeys // for automated tests to compare JSON strings, makes keys never in a random order
        // We are using custom date encoding because if there are milliseconds in Date object,
        // the default `secondsSince1970` will give a unix time with a decimal. The
        // Customer.io API does not accept timestamps with a decimal value unix time.
        encoder.dateEncodingStrategy = .custom { date, encoder in
            var container = encoder.singleValueContainer()
            let seconds = Int(date.timeIntervalSince1970)
            try container.encode(seconds)
        }
        return encoder
    }

    private let log: Logger

    init(log: Logger) {
        self.log = log
    }

    public func fromDictionary<T: Decodable>(_ dictionary: [AnyHashable: Any]) -> T? {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: dictionary)

            return fromJson(jsonData)
        } catch {
            log.error("\(error.localizedDescription), dictionary: \(dictionary)")
        }

        return nil
    }

    public func toDictionary<T: Encodable>(_ obj: T) -> [AnyHashable: Any]? {
        guard let data = toJson(obj) else {
            return nil
        }

        do {
            return try JSONSerialization.jsonObject(with: data, options: []) as? [AnyHashable: Any]
        } catch {
            log.error("\(error.localizedDescription), object: \(obj)")
        }

        return nil
    }

    /**
     Returns optional to be more convenient then try/catch all over the code base.

     It *should* be rare to have an issue with encoding and decoding JSON because the Customer.io API
     response formats are consistent and input data from the SDK functions are tied to a certain data
     type (if struct wants an Int, you can only pass an Int).

     The negative to this method is that we don't get to capture the `Error` to debug it if we don't
     expect to get an error. If we need this functionality, perhaps we should create a 2nd set of
     methods to this class that `throw` so you choose which function to use?
     */
    public func fromJson<T: Decodable>(_ json: Data, logErrors: Bool = true) -> T? {
        var errorStringToLog: String?

        do {
            let value = try decoder.decode(T.self, from: json)
            return value
        } catch DecodingError.keyNotFound(let key, let context) {
            errorStringToLog = """
            Decode key not found. Key: \(key),
            Json path: \(context.codingPath), json: \(json.string ?? "(error getting json string)")
            """
        } catch DecodingError.valueNotFound(let type, let context) {
            errorStringToLog = """
            Decode non-optional value not found. Value: \(type), Json path: \(context.codingPath), json: \(
                json
                    .string ?? "(error getting json string)"
            )
            """
        } catch DecodingError.typeMismatch(let type, let context) {
            errorStringToLog = """
            Decode type did not match payload. Type: \(type), Json path: \(context.codingPath), json: \(
                json
                    .string ?? "(error getting json string)"
            )
            """
        } catch DecodingError.dataCorrupted(let context) {
            errorStringToLog = """
            Decode data corrupted. Json path: \(context.codingPath), json: \(
                json
                    .string ?? "(error getting json string)"
            )
            """
        } catch {
            errorStringToLog = """
            Generic decode error. \(error.localizedDescription), json: \(json.string ?? "(error getting json string)")
            """
        }

        if let errorStringToLog = errorStringToLog {
            if logErrors {
                log.error(errorStringToLog)
            }
        }

        return nil
    }

    public func toJson<T: Encodable>(_ obj: T) -> Data? {
        do {
            let value = try encoder.encode(obj)
            return value
        } catch EncodingError.invalidValue(let value, let context) {
            self.log
                .error("Encoding could not encode value. \(value), Json path: \(context.codingPath), object: \(obj)")
        } catch {
            log.error("Generic encode error. \(error.localizedDescription), object: \(obj)")
        }

        return nil
    }

    // default values for parameters are designed for creating JSON strings to send to our API.
    // They are to meet the requirements of our API.
    public func toJsonString<T: Encodable>(
        _ obj: T,
        nilIfEmpty: Bool = true
    ) -> String? {
        guard let data = toJson(obj)
        else { return nil }

        let jsonString = data.string

        // Because we usually use JSON strings in API calls with Codable, empty JSON strings
        // don't get decoded into JSON HTTP request bodies. Therefore, we prefer `nil` to
        // avoid errors when performing HTTP requests.
        if nilIfEmpty, jsonString == "{}" {
            return nil
        }

        return jsonString
    }
}
