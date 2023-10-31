import Foundation

public enum CIOApiEndpoint {
    case findAccountRegion
    case identifyCustomer(identifier: String)
    case registerDevice(identifier: String)
    case deleteDevice(identifier: String, deviceToken: String)
    case trackCustomerEvent(identifier: String)
    case pushMetrics
    case trackDeliveryMetrics

    var path: String {
        switch self {
        case .findAccountRegion: return "/api/v1/accounts/region"
        case .identifyCustomer(let identifier): return "/api/v1/customers/\(identifier)"
        case .registerDevice(let identifier): return "/api/v1/customers/\(identifier)/devices"
        case .deleteDevice(
            let identifier,
            let deviceToken
        ): return "/api/v1/customers/\(identifier)/devices/\(deviceToken)"
        case .trackCustomerEvent(let identifier): return "/api/v1/customers/\(identifier)/events"
        case .pushMetrics: return "/push/events"
        case .trackDeliveryMetrics: return "/api/v1/cio_deliveries/events"
        }
    }

    var method: String {
        switch self {
        case .findAccountRegion: return "GET"
        case .identifyCustomer: return "PUT"
        case .registerDevice: return "PUT"
        case .deleteDevice: return "DELETE"
        case .trackCustomerEvent: return "POST"
        case .pushMetrics: return "POST"
        case .trackDeliveryMetrics: return "POST"
        }
    }
}

public extension CIOApiEndpoint {
    func getUrl(baseUrls: HttpBaseUrls) -> URL? {
        URL(string: getUrlString(baseUrls: baseUrls))
    }

    func getUrlString(baseUrls: HttpBaseUrls) -> String {
        // At this time, all endpoints use tracking endpoint so we only use only 1 base URL here.
        var baseUrl = baseUrls.trackingApi

        guard !baseUrl.isEmpty else {
            return ""
        }
        if baseUrl.last! == "/" {
            baseUrl = String(baseUrl.dropLast())
        }

        let fullPath = baseUrl + (path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? path)
        return fullPath
    }
}

/**
 Collection of the different base URLs for all the APIs of Customer.io.
 Each endpoint in `HttpEndpoint` knows what base API that it needs. That is where
 the full URL including path is constructed.
 */
public struct HttpBaseUrls: Equatable {
    let trackingApi: String

    static func getProduction(region: Region) -> HttpBaseUrls {
        HttpBaseUrls(trackingApi: region.productionTrackingUrl)
    }
}
