import CioInternalCommon
import Foundation
import UserNotifications

// Wrapper around UNUserNotificationCenter so it can be disabled
// in automated tests. Automated tests throw an exception when trying to access
// UNUserNotificationCenter.current()
protocol UserNotificationCenter: AutoMockable {
    var currentDelegate: UNUserNotificationCenterDelegate? { get set }
}

// sourcery: InjectRegister = "UserNotificationCenter"
class UserNotificationCenterImpl: UserNotificationCenter {
    var currentDelegate: UNUserNotificationCenterDelegate? {
        get {
            UNUserNotificationCenter.current().delegate
        }
        set {
            UNUserNotificationCenter.current().delegate = newValue
        }
    }
}
