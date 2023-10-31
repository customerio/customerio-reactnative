import Foundation

/// Metadata about a SDK wrapper/bridge made to use this Customer.io SDK.
public struct SdkWrapperConfig {
    /// What is the technology used for this wrapper?
    public let source: Source
    /// What version of your wrapper is installed?
    public let version: String

    /// All of the official SDK wrappers that we create around this SDK.
    /// At this time, we do not recommend to customers to build their own
    /// bridge/wrapper around our native mobile SDKs so there is no need
    /// to expand this to include more Sources besides ones that we use internally.
    public enum Source: String {
        case reactNative = "ReactNative"
        case expo = "Expo"
        case flutter = "Flutter"
    }

    public init(source: Source, version: String) {
        self.source = source
        self.version = version
    }
}
