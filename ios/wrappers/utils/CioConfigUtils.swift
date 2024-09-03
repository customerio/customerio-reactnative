import CioInternalCommon
import CioDataPipelines
import CioMessagingInApp

extension Region: Decodable {}

let logLevels = Set<String>(CioLogLevel.allCases.map(\.rawValue))

struct QASettings: Decodable {
    let cdnHost: String
    let apiHost: String
}

struct RCTCioConfig: Decodable {
    let cdpApiKey: String
    let siteId: String?
    let region: Region?
    let trackApplicationLifecycleEvents: Bool?
    let enableInApp: Bool?
    let qa: QASettings?
    
    static func from(_ json: AnyObject) throws -> Self {
        let data = try JSONSerialization.data(withJSONObject: json, options: [])
        let instance = try JSONDecoder().decode(Self.self, from: data)
        return instance
    }
}

struct CioConfig {
    let cdp: SDKConfigBuilderResult
    let inApp: MessagingInAppConfigOptions?
}

func ifNotNil<V, K>(_ value: V?, thenPassItTo: (V) -> K) {
    if let value {
        _ = thenPassItTo(value)
    }
}

func cioInitializeConfig(from config: RCTCioConfig, logLevel: String?) -> CioConfig {
    
    let cdpConfigBuilder =  SDKConfigBuilder(cdpApiKey: config.cdpApiKey)
    let cioLogLevel = CioLogLevel(rawValue: logLevel ?? "no log level")
    ifNotNil(config.siteId, thenPassItTo: cdpConfigBuilder.migrationSiteId)
    ifNotNil(config.region, thenPassItTo: cdpConfigBuilder.region)
    ifNotNil(config.trackApplicationLifecycleEvents, thenPassItTo: cdpConfigBuilder.trackApplicationLifecycleEvents)
    ifNotNil(cioLogLevel, thenPassItTo: cdpConfigBuilder.logLevel)
    ifNotNil(config.qa?.cdnHost, thenPassItTo: cdpConfigBuilder.cdnHost)
    ifNotNil(config.qa?.apiHost, thenPassItTo: cdpConfigBuilder.apiHost)
    
    var inAppConfig: MessagingInAppConfigOptions? = nil
    
    if let siteId = config.siteId, let region = config.region, let enableInApp = config.enableInApp, enableInApp {
        inAppConfig = MessagingInAppConfigBuilder(siteId: siteId, region: region).build()
    }
    
    return CioConfig(cdp: cdpConfigBuilder.build(), inApp: inAppConfig)
}

// To convert dictionary to Codable
struct AnyCodable: Codable {
    var value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let value = try? container.decode(String.self) {
            self.value = value
        } else if let value = try? container.decode(Int.self) {
            self.value = value
        } else if let value = try? container.decode(Double.self) {
            self.value = value
        } else if let value = try? container.decode(Bool.self) {
            self.value = value
        } else if let value = try? container.decode([String: AnyCodable].self) {
            self.value = value.mapValues { $0.value }
        } else if let value = try? container.decode([AnyCodable].self) {
            self.value = value.map { $0.value }
        } else if container.decodeNil() {
            self.value = NSNull()
        } else {
            throw DecodingError.typeMismatch(AnyCodable.self, DecodingError.Context(
                codingPath: decoder.codingPath,
                debugDescription: "Unsupported type"
            ))
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        if let value = value as? String {
            try container.encode(value)
        } else if let value = value as? Int {
            try container.encode(value)
        } else if let value = value as? Double {
            try container.encode(value)
        } else if let value = value as? Bool {
            try container.encode(value)
        } else if let value = value as? [String: Any] {
            try container.encode(value.mapValues { AnyCodable($0) })
        } else if let value = value as? [Any] {
            try container.encode(value.map { AnyCodable($0) })
        } else if value is NSNull {
            try container.encodeNil()
        } else {
            throw EncodingError.invalidValue(value, EncodingError.Context(
                codingPath: encoder.codingPath,
                debugDescription: "Unsupported type"
            ))
        }
    }
}