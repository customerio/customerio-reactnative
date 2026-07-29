import CioMessagingInbox
import Foundation
import SwiftUI
import UIKit

/// React Native wrapper hosting the SwiftUI `NotificationInboxView` (the Jist-rendered message
/// list) inside a `UIHostingController`. No events; sizing is driven by the JS `style` prop.
/// Message actions are handled by the existing global InboxEventListener.
@available(iOS 15.0, *)
@objc(ReactNotificationInboxView)
class ReactNotificationInboxView: NSObject {
    private let hostingController: UIHostingController<NotificationInboxView>

    @objc
    init(containerView: UIView) {
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

    @objc
    func updateLayout(_ boundsValue: NSValue) {
        hostingController.view.frame = boundsValue.cgRectValue
        hostingController.view.setNeedsLayout()
        hostingController.view.layoutIfNeeded()
    }

    @objc
    func prepareForRecycle() {
        hostingController.view.removeFromSuperview()
    }
}
