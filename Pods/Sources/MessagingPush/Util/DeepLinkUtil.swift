import CioInternalCommon
import Foundation
#if canImport(UIKit)
import UIKit
#endif

protocol DeepLinkUtil: AutoMockable {
    func handleDeepLink(_ deepLinkUrl: URL)
}

@available(iOSApplicationExtension, unavailable)
// sourcery: InjectRegister = "DeepLinkUtil"
class DeepLinkUtilImpl: DeepLinkUtil {
    private let logger: Logger
    private let uiKit: UIKitWrapper

    init(logger: Logger, uiKitWrapper: UIKitWrapper) {
        self.logger = logger
        self.uiKit = uiKitWrapper
    }

    func handleDeepLink(_ deepLinkUrl: URL) {
        logger.info("Found a deep link inside of a push notification.")
        logger.debug("deep link found in push: \(deepLinkUrl)")

        /*
         There are 2 types of deep links:
         1. Universal Links which give URL format of a webpage using `http://` or `https://`
         2. App scheme which give URL format using a prototol other then `http://` or `https://`.

         First, try to open the link inside of the host app. This is to keep compatability with Universal Links.
         Learn more of edge case: https://github.com/customerio/customerio-ios/issues/262

         Fallback to opening the URL through a sytem call if:
         1. deep link is an app scheme URL
         2. Customer has not implemented the correct function in their host app to handle universal link:
         ```
         func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool
         ```
         3. Customer returned `false` from ^^^ function.
         */
        let ifHandled = uiKit.continueNSUserActivity(webpageURL: deepLinkUrl)

        if !ifHandled {
            logger.debug("Opening deep link through system call. Deep link: \(deepLinkUrl)")
            uiKit.open(url: deepLinkUrl)
        }
    }
}
