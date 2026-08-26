import CioMessagingPushAPN
import UIKit

@main
class AppDelegateWithCioIntegration: CioAppDelegateWrapper<AppDelegate> {}

class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        MessagingPushAPN.initialize(
            withConfig: MessagingPushConfigBuilder().build()
        )
        return true
    }
}
