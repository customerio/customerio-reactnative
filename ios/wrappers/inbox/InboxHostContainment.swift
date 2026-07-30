import Foundation
import UIKit

/// Shared view-controller containment for the inbox `UIHostingController` hosts.
///
/// Adopting only a hosting controller's `view` leaves the controller outside the view-controller
/// hierarchy. UIKit then has no presentation context or trait/safe-area chain for it, which showed up
/// as a phantom top margin in the overlay's sheet (the sheet content resolved insets against the
/// wrong container) and means no lifecycle callbacks ever reach the hosted SwiftUI. Native usage does
/// not hit this because there the hosting controller *is* a real pushed view controller.
///
/// Containment has to be deferred until the Fabric view is actually in a window: React Native creates
/// component views before mounting them, so at `init` there is no parent controller to attach to.
enum InboxHostContainment {
    /// Nearest view controller up the responder chain, or nil while the view is unmounted.
    static func nearestViewController(from view: UIView?) -> UIViewController? {
        var responder: UIResponder? = view
        while let current = responder {
            if let viewController = current as? UIViewController {
                return viewController
            }
            responder = current.next
        }
        return nil
    }

    /// Attaches `child` to the controller owning `view`. No-op when already attached or unmounted.
    static func attach(_ child: UIViewController, hostedIn view: UIView?) {
        guard child.parent == nil, let parent = nearestViewController(from: view) else { return }
        parent.addChild(child)
        child.didMove(toParent: parent)
    }

    /// Detaches `child` from its parent. No-op when it was never attached.
    static func detach(_ child: UIViewController) {
        guard child.parent != nil else { return }
        child.willMove(toParent: nil)
        child.removeFromParent()
    }
}
