import Foundation

/**
 Stores data in key/value pairs.
 */
public protocol KeyValueStorage {
    func switchToGlobalDataStore()

    func integer(_ key: KeyValueStorageKey) -> Int?
    func setInt(_ value: Int?, forKey key: KeyValueStorageKey)
    func double(_ key: KeyValueStorageKey) -> Double?
    func setDouble(_ value: Double?, forKey key: KeyValueStorageKey)
    func string(_ key: KeyValueStorageKey) -> String?
    func setString(_ value: String?, forKey key: KeyValueStorageKey)
    func date(_ key: KeyValueStorageKey) -> Date?
    func setDate(_ value: Date?, forKey key: KeyValueStorageKey)
    func deleteAll()
}

/*
 Uses UserDefaults to store data in key/value pairs.
 */
// sourcery: InjectRegister = "KeyValueStorage"
public class UserDefaultsKeyValueStorage: KeyValueStorage {
    private var siteId: String?
    private let deviceMetricsGrabber: DeviceMetricsGrabber

    private var userDefaults: UserDefaults? {
        UserDefaults(suiteName: getFileName())
    }

    init(sdkConfig: SdkConfig, deviceMetricsGrabber: DeviceMetricsGrabber) {
        self.siteId = sdkConfig.siteId
        self.deviceMetricsGrabber = deviceMetricsGrabber
    }

    // Used for global data that's relevant to *all* of the site-ids (not sandboxed).
    // Instead of the more common way the SDK stores data by sandboxing all of that data by site-id.
    // See `GlobalDataStore` for data that is relevant for *all* site-ids in the SDK.
    public func switchToGlobalDataStore() {
        siteId = nil
    }

    /**
     We want to sandbox all of the data for each CIO workspace and app.
     Therefore, we use the app's bundle ID to be unique to the app and the siteId to separate all of the sites.

     We also need to have 1 set of UserPreferences that all workspaces of an app share.
     For these moments, use `shared` as the `siteId` value.
     */
    func getFileName() -> String {
        var appUniqueIdentifier = ""
        if let appBundleId = deviceMetricsGrabber.appBundleId {
            appUniqueIdentifier = ".\(appBundleId)"
        }

        var siteIdPart = ".shared" // used for storing global data used for all site-ids.
        if let siteId = siteId { // if a siteid is given to this instance, we dont store global data with this instance.
            siteIdPart = ".\(siteId)"
        }

        return "io.customer.sdk\(appUniqueIdentifier)\(siteIdPart)"
    }

    public func integer(_ key: KeyValueStorageKey) -> Int? {
        let value = userDefaults?.integer(forKey: key.rawValue)
        return value == 0 ? nil : value
    }

    public func setInt(_ value: Int?, forKey key: KeyValueStorageKey) {
        userDefaults?.set(value, forKey: key.rawValue)
    }

    public func double(_ key: KeyValueStorageKey) -> Double? {
        let value = userDefaults?.double(forKey: key.rawValue)
        return value == 0 ? nil : value
    }

    public func setDouble(_ value: Double?, forKey key: KeyValueStorageKey) {
        userDefaults?.set(value, forKey: key.rawValue)
    }

    public func string(_ key: KeyValueStorageKey) -> String? {
        userDefaults?.string(forKey: key.rawValue)
    }

    public func setString(_ value: String?, forKey key: KeyValueStorageKey) {
        userDefaults?.set(value, forKey: key.rawValue)
    }

    public func date(_ key: KeyValueStorageKey) -> Date? {
        guard let millis = userDefaults?.double(forKey: key.rawValue), millis > 0 else {
            return nil
        }

        return Date(timeIntervalSince1970: millis)
    }

    public func setDate(_ value: Date?, forKey key: KeyValueStorageKey) {
        userDefaults?.set(value?.timeIntervalSince1970, forKey: key.rawValue)
    }

    public func deleteAll() {
        userDefaults?.deleteAll()
    }
}
