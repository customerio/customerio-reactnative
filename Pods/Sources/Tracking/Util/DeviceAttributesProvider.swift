import CioInternalCommon
import Foundation

protocol DeviceAttributesProvider: AutoMockable {
    func getDefaultDeviceAttributes(onComplete: @escaping ([String: Any]) -> Void)
}

// sourcery: InjectRegister = "DeviceAttributesProvider"
class SdkDeviceAttributesProvider: DeviceAttributesProvider {
    private let sdkConfig: SdkConfig
    private let deviceInfo: DeviceInfo

    init(sdkConfig: SdkConfig, deviceInfo: DeviceInfo) {
        self.sdkConfig = sdkConfig
        self.deviceInfo = deviceInfo
    }

    func getDefaultDeviceAttributes(onComplete: @escaping ([String: Any]) -> Void) {
        if !sdkConfig.autoTrackDeviceAttributes {
            onComplete([:])
            return
        }

        var deviceAttributes = [
            "cio_sdk_version": getSdkVersionAttribute(),
            "app_version": deviceInfo.customerAppVersion,
            "device_locale": deviceInfo.deviceLocale,
            "device_manufacturer": deviceInfo.deviceManufacturer
        ]
        if let deviceModel = deviceInfo.deviceModel {
            deviceAttributes["device_model"] = deviceModel
        }
        if let deviceOsVersion = deviceInfo.osVersion {
            deviceAttributes["device_os"] = deviceOsVersion
        }
        deviceInfo.isPushSubscribed { isSubscribed in
            deviceAttributes["push_enabled"] = String(isSubscribed)

            onComplete(deviceAttributes)
        }
    }

    func getSdkVersionAttribute() -> String {
        var sdkVersion = deviceInfo.sdkVersion

        // Allow SDK wrapper to override the SDK version
        if let sdkWrapperConfig = sdkConfig._sdkWrapperConfig {
            sdkVersion = sdkWrapperConfig.version
        }

        return sdkVersion
    }
}
