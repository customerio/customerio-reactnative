import Foundation
#if canImport(UIKit)
import UIKit

public extension UIApplication {
    // since some extension functions may be able to run in iOS app extensions, only disable for this 1 function
    @available(iOSApplicationExtension, unavailable)
    func open(url: URL) {
        open(url, options: [:]) { _ in }
    }
}

public extension UIViewController {
    // find the bundleId of the framework this View belongs in. This can be used to differentiate Views that belong to host app and Views that belong to SDKs/frameworks.
    var bundleIdOfView: String? {
        Bundle(for: type(of: self)).bundleIdentifier
    }
}
#endif
