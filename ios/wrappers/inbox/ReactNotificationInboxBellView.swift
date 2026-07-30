import CioMessagingInbox
import Foundation
import SwiftUI
import UIKit

/// React Native wrapper hosting the SwiftUI `NotificationInboxOverlay` inside a `UIHostingController`.
///
/// Despite the name, the hosted composition is the overlay rather than the bare `NotificationInboxBell`:
/// only the overlay ties the bell to the SDK's own inbox sheet, and the wrapper deliberately does not
/// reimplement panel presentation. Sized to the frame React Native assigns, that composition *is* a bell
/// that opens the inbox — the component wrappers expose.
///
/// Remote branding still styles the bell (colors, icon). Branding's bell *position* has no effect here:
/// alignment resolves inside this view's frame, so the host owns placement via `style`.
///
/// iOS 16+ because the panel is a sheet with system detents.
@available(iOS 16.0, *)
@objc(ReactNotificationInboxBellView)
class ReactNotificationInboxBellView: NSObject {
    private weak var eventEmitter: AnyObject?
    private weak var containerView: UIView?
    private let hostingController: UIHostingController<NotificationInboxOverlay>

    @objc
    init(containerView: UIView) {
        self.containerView = containerView
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

        // Observational tap reporting. The SDK owns presentation, so this recognizer must not consume
        // the touch: `cancelsTouchesInView = false` lets SwiftUI still receive it and open the sheet.
        // It reports any tap inside this view's frame, which is the bell when the view is sized to it.
        let tapObserver = UITapGestureRecognizer(target: self, action: #selector(handleObservedTap))
        tapObserver.cancelsTouchesInView = false
        tapObserver.delaysTouchesEnded = false
        containerView.addGestureRecognizer(tapObserver)
    }

    @objc
    func setEventEmitter(_ eventEmitter: AnyObject?) {
        self.eventEmitter = eventEmitter
    }

    /// Adds the hosting controller to the view-controller hierarchy once the view is in a window.
    ///
    /// Without this the controller is orphaned, and the sheet it presents resolves its safe-area insets
    /// against the wrong container — which showed up as a phantom top margin when dragging the sheet.
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
        // Deliberately does NOT remove the hosted view from its container.
        //
        // Fabric recycles the component view, and detaching the SwiftUI view here with nothing to
        // re-attach it made a reused view come back blank. `ReactInlineMessageView` does not touch the
        // hierarchy either. Containment is released here because a recycled view is leaving its parent.
        detachFromParentViewController()
    }

    // MARK: - Event Emission

    @objc
    private func handleObservedTap() {
        emitEvent("emitOnTapEvent:", payload: [:])
    }

    /// Mirrors `ReactInlineMessageView.emitEvent`: asserts rather than returning silently, so a
    /// mis-wired emitter surfaces in debug instead of the tap simply never reaching JS.
    private func emitEvent(_ selectorName: String, payload: [String: Any?]) {
        guard let emitter = eventEmitter else {
            assertionFailure("Event emitter is nil when trying to emit \(selectorName)")
            return
        }

        let selector = Selector((selectorName))
        guard emitter.responds(to: selector) else {
            assertionFailure("Event emitter does not respond to selector: \(selectorName)")
            return
        }

        _ = emitter.perform(selector, with: payload as NSDictionary)
    }
}
