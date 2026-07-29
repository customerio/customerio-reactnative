import CioMessagingInbox
import Foundation
import SwiftUI
import UIKit

/// React Native wrapper hosting the SwiftUI `NotificationInboxOverlay` (drop-in floating bell +
/// slide-out panel) inside a `UIHostingController`.
///
/// Mirrors `ReactInlineMessageView`: the Objective-C++ Fabric view (`RCTNotificationInboxOverlayNative`)
/// owns this object via runtime class resolution and forwards layout/lifecycle.
///
/// iOS 16+ because the native overlay presents its panel in a sheet with system detents. The bell and
/// list components are iOS 13+; only this drop-in composition carries the higher floor.
@available(iOS 16.0, *)
@objc(ReactNotificationInboxOverlayView)
class ReactNotificationInboxOverlayView: NSObject {
    private weak var containerView: UIView?
    private let hostingController: UIHostingController<NotificationInboxOverlay>

    @objc
    init(containerView: UIView) {
        self.containerView = containerView
        // The native overlay owns panel presentation itself (its own sheet), so there is no
        // host-facing open/close callback to bridge to JS.
        self.hostingController = UIHostingController(rootView: NotificationInboxOverlay())
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
