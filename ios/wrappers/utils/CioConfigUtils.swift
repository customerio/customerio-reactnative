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
