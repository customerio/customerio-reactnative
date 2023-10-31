import Foundation

/**
 The API returns error response bodies in the format:
 ```
 {"meta": { "error": "invalid id" }}
 ```
 */
public class ErrorMessageResponse: Codable {
    let meta: Meta

    public class Meta: Codable {
        let error: String

        enum CodingKeys: String, CodingKey {
            case error
        }
    }

    enum CodingKeys: String, CodingKey {
        case meta
    }
}

/**
 The API returns error response bodies in the format:
 ```
 {"meta": { "errors": ["invalid id"] }}
 ```
 */
public class ErrorsMessageResponse: Codable {
    let meta: Meta

    public class Meta: Codable {
        let errors: [String]

        enum CodingKeys: String, CodingKey {
            case errors
        }
    }

    enum CodingKeys: String, CodingKey {
        case meta
    }
}
