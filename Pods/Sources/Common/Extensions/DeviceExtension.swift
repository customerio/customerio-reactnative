import Foundation
#if canImport(UIKit)
import UIKit

/**
 Extend `UIDevice` to get user's device information such as
 device's model. If running on Simulator `deviceModelCode`
 will return values like`x86_64` but when running on a device, this function
 returns exact device model for example, `iPhone12,3`

 Use case :
 To get model detail, simply use

 let deviceModelInfo = UIDevice.deviceModelCode
 */
public extension UIDevice {
    static let deviceModelCode: String = {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier
    }()
}
#endif
