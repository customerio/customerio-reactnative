import Foundation
#if canImport(UIKit)
import UIKit
#endif

/**
 Configuration options for the Customer.io SDK.
 See `CustomerIO.config()` to configurate the SDK.

 Example use case:
 ```
 // create a new instance
 let sdkConfigInstance = SdkConfig.Factory.create(region: .US)
 // now, you can modify it
 sdkConfigInstance.trackingApiUrl = "https..."
 sdkConfigInstance.autoTrackPushEvents = false
 ```
 */
public struct SdkConfig {
    // Used to create new instance of SdkConfig when the SDK is initialized.
    // Then, each property of the SdkConfig object can be modified by the user.
    public enum Factory {
        public static func create(siteId: String, apiKey: String, region: Region) -> SdkConfig {
            SdkConfig(
                siteId: siteId,
                apiKey: apiKey,
                region: region,
                trackingApiUrl: region.productionTrackingUrl,
                autoTrackPushEvents: true,
                backgroundQueueMinNumberOfTasks: 10,
                backgroundQueueSecondsDelay: 30,
                backgroundQueueExpiredSeconds: Seconds.secondsFromDays(3),
                logLevel: CioLogLevel.error,
                autoTrackScreenViews: false,
                filterAutoScreenViewEvents: nil,
                autoTrackDeviceAttributes: true
            )
        }
    }

    public mutating func modify(params: [String: Any]) {
        // Each SDK config option should be able to be set from `param` map.
        // If one isn't provided, use the default value instead.

        // If a parameter takes more logic to calculate, perform the logic up here.
        if let logLevelStringValue = params[Keys.logLevel.rawValue] as? String, let paramLogLevel =
            CioLogLevel.getLogLevel(for: logLevelStringValue) {
            logLevel = paramLogLevel
        }

        // Construct object with all required parameters. Each config option should be provided from `params` or a default value.
        // Define default values here in constructor instead of in struct properties. This is by design so in the future if we add
        // a new SDK config option to the struct, we get a compiler error here in the constructor reminding us that we need to
        // add a way for `params` to override the SDK config option.
        if let autoTrackDeviceAttributes = params[Keys.autoTrackDeviceAttributes.rawValue] as? Bool {
            self.autoTrackDeviceAttributes = autoTrackDeviceAttributes
        }
        if let autoTrackPushEvents = params[Keys.autoTrackPushEvents.rawValue] as? Bool {
            self.autoTrackPushEvents = autoTrackPushEvents
        }
        if let autoTrackScreenViews = params[Keys.autoTrackScreenViews.rawValue] as? Bool {
            self.autoTrackScreenViews = autoTrackScreenViews
        }
        if let backgroundQueueMinNumberOfTasks = params[Keys.backgroundQueueMinNumberOfTasks.rawValue] as? Int {
            self.backgroundQueueMinNumberOfTasks = backgroundQueueMinNumberOfTasks
        }
        if let backgroundQueueSecondsDelay = params[Keys.backgroundQueueSecondsDelay.rawValue] as? Seconds {
            self.backgroundQueueSecondsDelay = backgroundQueueSecondsDelay
        }
        if let backgroundQueueExpiredSeconds = params[Keys.backgroundQueueExpiredSeconds.rawValue] as? Seconds {
            self.backgroundQueueExpiredSeconds = backgroundQueueExpiredSeconds
        }
        if let trackingApiUrl = params[Keys.trackingApiUrl.rawValue] as? String, !trackingApiUrl.isEmpty {
            self.trackingApiUrl = trackingApiUrl
        }

        if let sdkSource = params[Keys.source.rawValue] as? String, let pversion = params[Keys.sourceVersion.rawValue] as? String, let sdkConfigSource = SdkWrapperConfig.Source(rawValue: sdkSource) {
            _sdkWrapperConfig = SdkWrapperConfig(source: sdkConfigSource, version: pversion)
        }
    }

    // Constants that SDK wrappers can use with `modify` function for setting configuration options with strings.
    // It's important to keep these values backwards compatible to avoid breaking SDK wrappers.
    public enum Keys: String { // Constants used to map each of the options in SdkConfig
        // configure workspace environment
        case siteId
        case apiKey
        case region
        // config features
        case trackingApiUrl
        case autoTrackDeviceAttributes
        case autoTrackScreenViews
        case logLevel
        case autoTrackPushEvents
        case backgroundQueueMinNumberOfTasks
        case backgroundQueueSecondsDelay
        case backgroundQueueExpiredSeconds
        // SDK wrapper config
        case source
        case sourceVersion = "version"
    }

    /// Immutable property to store the workspace site id set during SDK initialization.
    public let siteId: String

    /// Immutable property to store the workspace api key set during SDK initialization.
    public let apiKey: String

    /// Immutable property to store the workspace Region set during SDK initialization.
    public let region: Region

    /**
     Base URL to use for the Customer.io track API. You will more then likely not modify this value.

     If you override this value, `Region` set when initializing the SDK will be ignored.
     */
    public var trackingApiUrl: String

    /**
     Automatic tracking of push events will automatically generate `opened` and `delivered` metrics
     for push notifications sent by Customer.io
     */
    public var autoTrackPushEvents: Bool

    /**
     Number of tasks in the background queue before the queue begins operating.
     This is mostly used during development to test configuration is setup. We do not recommend
     modifying this value because it impacts battery life of mobile device.
     */
    public var backgroundQueueMinNumberOfTasks: Int

    /// The number of seconds to delay running queue after a task has been added to it.
    public var backgroundQueueSecondsDelay: Seconds
    /**
     * The number of seconds old a queue task is when it is "expired" and should be deleted.
     * We do not recommend modifying this value because it risks losing data or taking up too much
     * space on the user's device.
     */
    public var backgroundQueueExpiredSeconds: Seconds

    /// To help you get setup with the SDK or debug SDK, change the log level of logs you
    /// wish to view from the SDK.
    public var logLevel: CioLogLevel

    /**
     Automatic tracking of screen views will generate `screen`-type events on every screen transition within
     your application.
     */
    public var autoTrackScreenViews: Bool

    #if canImport(UIKit)
    /**
     Filter automatic screenview events to remove events that are irrelevant to your app.

     Return `true` from function if you would like the screenview event to be tracked.

     Default: `nil`, which uses the default filter function packaged by the SDK. Provide a non-nil value to not call the SDK's filtering.
     */
    public var filterAutoScreenViewEvents: ((UIViewController) -> Bool)?
    #endif

    /**
     Handler to be called by our automatic screen tracker to generate `screen` event body variables. You can use
     this to override our defaults and pass custom values in the body of the `screen` event
     */
    public var autoScreenViewBody: (() -> [String: Any])?

    /**
     Enable this property if you want SDK to automatic tracking of device attributes such as
     operating system, device locale, device model, app version etc
     */
    public var autoTrackDeviceAttributes: Bool

    var httpBaseUrls: HttpBaseUrls {
        HttpBaseUrls(trackingApi: trackingApiUrl)
    }

    // property is used internally so disable swiftlint rule
    /**
     Used internally at Customer.io to override some information in the SDK when the SDK is being used
     as a wrapper/bridge such as with ReactNative.
     */
    public var _sdkWrapperConfig: SdkWrapperConfig? // swiftlint:disable:this identifier_name
}

/**
 SDK configuration just for rich push feature of the SDK.

 Construct an instance like you would `SdkConfig`.

 We have a separate SDK config just for rich push because:
 1. Instance of SDK inside of a Notification Service Extension does not have as many features to provide
 compared to running in a host app. Therefore, we don't need to expose as many SDK config options to customers.
 2. The SDK code needs to override some configuration options when running inside of a Notication Service Extension.
 We don't want customers to modify some of these overriden config options as it may effect some features of rich push.

 Note: To not make the SDK code more complex, convert `NotificationServiceExtensionSdkConfig` to an instance of `SdkConfig` when SDK is initialized.
 The SDK should not have conditional logic handling different SDK config objects. The SDK should only have to handle `SdkConfig`.
 */
public struct NotificationServiceExtensionSdkConfig {
    /// Keep reference to region as it's needed for `toSdkConfig()`
    private var siteId: String
    /// Keep reference to region as it's needed for `toSdkConfig()`
    private var apiKey: String
    /// Keep reference to region as it's needed for `toSdkConfig()`
    private var region: Region
    /// See `SdkConfig.trackingApiUrl`
    public var trackingApiUrl: String
    /// See `SdkConfig.autoTrackPushEvents`
    public var autoTrackPushEvents: Bool
    /// See `SdkConfig.logLevel`
    public var logLevel: CioLogLevel
    /// See `SdkConfig.autoTrackDeviceAttributes`
    public var autoTrackDeviceAttributes: Bool
    // property is used internally so disable swiftlint rule
    /**
     Used internally at Customer.io to override some information in the SDK when the SDK is being used
     as a wrapper/bridge such as with ReactNative.
     */
    public var _sdkWrapperConfig: SdkWrapperConfig? // swiftlint:disable:this identifier_name

    // Used to create new instance when the SDK is initialized.
    // Then, each property can be modified by the user.
    public enum Factory {
        public static func create(siteId: String, apiKey: String, region: Region) -> NotificationServiceExtensionSdkConfig {
            let defaultSdkConfig = SdkConfig.Factory.create(siteId: siteId, apiKey: apiKey, region: region)

            return NotificationServiceExtensionSdkConfig(
                siteId: siteId,
                apiKey: apiKey,
                region: region,
                trackingApiUrl: defaultSdkConfig.trackingApiUrl,
                autoTrackPushEvents: defaultSdkConfig.autoTrackPushEvents,
                logLevel: defaultSdkConfig.logLevel,
                autoTrackDeviceAttributes: defaultSdkConfig.autoTrackDeviceAttributes
            )
        }
    }

    /// Convert to `SdkConfig` before being used in the SDK. For make the SDK code base easier to maintain, the SDK is
    /// designed to only handle a `SdkCofig` object.
    /// Therefore, we need to convert this object to an `SdkConfig` instance in SDK initialization so the SDK can use
    /// it.
    public func toSdkConfig() -> SdkConfig {
        var sdkConfig = SdkConfig.Factory.create(siteId: siteId, apiKey: apiKey, region: region)

        sdkConfig.autoTrackPushEvents = autoTrackPushEvents
        sdkConfig.logLevel = logLevel
        sdkConfig.autoTrackDeviceAttributes = autoTrackDeviceAttributes
        sdkConfig._sdkWrapperConfig = _sdkWrapperConfig

        // Default to running tasks added to the BQ immediately.
        // Since a Notification Service Extension is only in memory for a small amount of time,
        // we need to bypass the background queue default behavior to make sure that HTTP tasks
        // have an opportunity to execute before the OS kills the Notification Service Extension.
        //
        // Customers should not be able to modify these values in a Notification Service Extension.
        // Or, they may experience some events (such as push metrics) not being delivered as expected to CIO.
        sdkConfig.backgroundQueueMinNumberOfTasks = 1
        sdkConfig.backgroundQueueSecondsDelay = 0

        return sdkConfig
    }
}
