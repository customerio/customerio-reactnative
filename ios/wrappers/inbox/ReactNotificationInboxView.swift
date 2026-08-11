import CioMessagingInbox
import Foundation
import SwiftUI
import UIKit

/// React Native wrapper hosting the SwiftUI `NotificationInboxView` (the Jist-rendered message
/// list) inside a `UIHostingController`. No events; sizing is driven by the JS `style` prop.
/// Message actions are handled by the existing global InboxEventListener.
/// No `@available` annotation, matching `ReactInlineMessageView`: the podspec enforces the
/// Customer.io iOS 15 floor while preserving a higher minimum required by React Native.
@objc(ReactNotificationInboxView)
class ReactNotificationInboxView: NSObject {
    private weak var containerView: UIView?
    private let hostingController: UIHostingController<NotificationInboxView>

    @objc
    init(containerView: UIView) {
        self.containerView = containerView
        self.hostingController = UIHostingController(rootView: NotificationInboxView())
        super.init()

        let hostedView = hostingController.view!
        hostedView.backgroundColor = .clear
        hostedView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(hostedView)
        NSLayoutConstraint.activate([
            hostedView.topAnchor.constraint(equalTo: containerView.topAnchor),
            hostedView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            hostedView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            hostedView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor)
        ])
    }

    // Accepts the emitter for API symmetry with the other inbox views; this view emits no events.
    @objc
    func setEventEmitter(_ eventEmitter: AnyObject?) {}

    /// Adds the hosting controller to the view-controller hierarchy once the view is in a window, so the
    /// hosted SwiftUI gets a correct trait/safe-area chain and lifecycle callbacks instead of being
    /// driven by an orphaned controller.
    @objc
    func attachToParentViewController() {
        InboxHostContainment.attach(hostingController, hostedIn: containerView)
    }

    @objc
    func detachFromParentViewController() {
        InboxHostContainment.detach(hostingController)
    }

    @objc
    func updateLayout(_ boundsValue: NSValue) {
        hostingController.view.frame = boundsValue.cgRectValue
        hostingController.view.setNeedsLayout()
        hostingController.view.layoutIfNeeded()
    }

    @objc
    func prepareForRecycle() {
        detachFromParentViewController()
        // Deliberately does NOT remove the hosted view from its container.
        //
        // Fabric recycles the component view, and the previous version detached the SwiftUI view here
        // with nothing to re-attach it, so a reused view came back blank. `ReactInlineMessageView`
        // does not touch the hierarchy either — it detaches observers (`onViewDetached`) and
        // re-attaches in `setupForReuse`. These hosts have no props and no observers to reset, so
        // there is nothing to undo: the hosted view stays mounted and is reused as-is.
    }
}
