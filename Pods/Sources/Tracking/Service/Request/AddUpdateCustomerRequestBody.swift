import Foundation

/// https://customer.io/docs/api/#operation/identify
struct AddUpdateCustomerRequestBody: Codable {
    let email: String?
    let anonymousId: String?

    enum CodingKeys: String, CodingKey {
        case email
        case anonymousId = "anonymous_id"
    }
}
