import Foundation
#if canImport(UIKit)
import UIKit
#endif

/*
 Because our codebase uses `#if canImport(UIKit)` to avoid being tightly coupled to iOS, this utility class exists to
 encapsulate all UIKit operations so our codebase doesn't need to have error-prone and boilerplate `#if ...UIKit...` code in many places.
 */
@available(iOSApplicationExtension, unavailable)
public protocol UIKitWrapper: AutoMockable {
    func open(url: URL)
    func continueNSUserActivity(webpageURL: URL) -> Bool
}

@available(iOSApplicationExtension, unavailable)
// sourcery: InjectRegister = "UIKitWrapper"
public class UIKitWrapperImpl: UIKitWrapper {
    public func open(url: URL) {
        #if canImport(UIKit)
        UIApplication.shared.open(url: url)
        #endif
    }

    public func continueNSUserActivity(webpageURL: URL) -> Bool {
        #if canImport(UIKit)
        guard isLinkValidNSUserActivityLink(webpageURL) else {
            return false
        }

        let openLinkInHostAppActivity = NSUserActivity(activityType: NSUserActivityTypeBrowsingWeb)
        openLinkInHostAppActivity.webpageURL = webpageURL

        let didHostAppHandleLink = UIApplication.shared.delegate?.application?(UIApplication.shared, continue: openLinkInHostAppActivity, restorationHandler: { _ in }) ?? false

        return didHostAppHandleLink
        #else
        return false
        #endif
    }

    // When using `NSUserActivity.webpageURL`, only certain URL schemes are allowed. An exception will be thrown otherwise which is why we have this function.
    func isLinkValidNSUserActivityLink(_ url: URL) -> Bool {
        guard let schemeOfUrl = url.scheme else {
            return false
        }

        // All allowed schemes in docs: https://developer.apple.com/documentation/foundation/nsuseractivity/1418086-webpageurl
        let allowedSchemes = ["http", "https"]

        return allowedSchemes.contains(schemeOfUrl)
    }
}
