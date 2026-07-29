import CioMessagingInbox
import Foundation
import SwiftUI
import UIKit

/// React Native wrapper hosting the SwiftUI `NotificationInboxBell` (just the bell) inside a
/// `UIHostingController`. Emits `onTap` to JS; the host presents its own inbox UI.
///
/// No `@available` annotation, matching `ReactInlineMessageView`: the native bell is iOS 13+, so the
/// pod's own floor (`min_ios_version_supported`) governs. Only the overlay carries a higher floor.
@objc(ReactNotificationInboxBellView)
class ReactNotificationInboxBellView: NSObject {
    private weak var eventEmitter: AnyObject?
    private let hostingController: UIHostingController<NotificationInboxBell>

    @objc
    init(containerView: UIView) {
        var emitClosure: (() -> Void)?
        let bell = NotificationInboxBell(onTap: {
            emitClosure?()
        })
        self.hostingController = UIHostingController(rootView: bell)
        super.init()

        emitClosure = { [weak self] in
            self?.sendTap()
        }

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
    func setEventEmitter(_ eventEmitter: AnyObject?) {
        self.eventEmitter = eventEmitter
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
        // Fabric recycles the component view, and the previous version detached the SwiftUI view here
        // with nothing to re-attach it, so a reused view came back blank. `ReactInlineMessageView`
        // does not touch the hierarchy either — it detaches observers (`onViewDetached`) and
        // re-attaches in `setupForReuse`. These hosts have no props and no observers to reset, so
        // there is nothing to undo: the hosted view stays mounted and is reused as-is.
    }

    // MARK: - Event Emission Helper

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

    private func sendTap() {
        emitEvent("emitOnTapEvent:", payload: [:])
    }
}
