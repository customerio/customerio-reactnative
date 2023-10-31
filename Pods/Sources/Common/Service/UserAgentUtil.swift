import Foundation

public protocol UserAgentUtil: AutoMockable {
    func getUserAgentHeaderValue() -> String
}

// sourcery: InjectRegister = "UserAgentUtil"
public class UserAgentUtilImpl: UserAgentUtil {
    private let deviceInfo: DeviceInfo
    private let sdkWrapperConfig: SdkWrapperConfig?

    init(deviceInfo: DeviceInfo, sdkConfig: SdkConfig) {
        self.deviceInfo = deviceInfo
        self.sdkWrapperConfig = sdkConfig._sdkWrapperConfig
    }

    /**
     * getUserAgent - To get `user-agent` header value. This value depends on SDK version
     * and device detail such as OS version, device model, customer's app name etc
     *
     * In case, UIKit is available then this function returns value in following format :
     * `Customer.io iOS Client/1.0.0-alpha.16 (iPhone 11 Pro; iOS 14.5) User App/1.0`
     *
     * Otherwise will return
     * `Customer.io iOS Client/1.0.0-alpha.16`
     */
    public func getUserAgentHeaderValue() -> String {
        var userAgent = "Customer.io iOS Client/\(deviceInfo.sdkVersion)"

        if let sdkWrapperConfig = sdkWrapperConfig {
            userAgent = "Customer.io \(sdkWrapperConfig.source.rawValue) Client/\(sdkWrapperConfig.version)"
        }

        if let deviceModel = deviceInfo.deviceModel,
           let deviceOsVersion = deviceInfo.osVersion,
           let deviceOsName = deviceInfo.osName {
            userAgent += " (\(deviceModel); \(deviceOsName) \(deviceOsVersion))"
            userAgent += " \(deviceInfo.customerBundleId)/\(deviceInfo.customerAppVersion)"
        }

        return userAgent
    }
}
