import CioMessagingInbox
import Foundation
import SwiftUI
import UIKit

/// React Native wrapper hosting the SwiftUI `NotificationInboxBell` (just the bell) inside a
/// `UIHostingController`. Emits `onTap` to JS; the host presents its own inbox UI.
@available(iOS 15.0, *)
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
        hostingController.view.removeFromSuperview()
    }

    private func sendTap() {
        guard let emitter = eventEmitter else { return }
        let selector = Selector(("emitOnTapEvent:"))
        guard emitter.responds(to: selector) else { return }
        _ = emitter.perform(selector, with: [:] as NSDictionary)
    }
}
