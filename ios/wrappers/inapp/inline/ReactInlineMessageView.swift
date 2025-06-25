import CioMessagingInApp
import Foundation
import UIKit

/// React Native wrapper for inline message display with content view lifecycle management.
///
/// This Swift class provides the actual functionality while allowing Objective-C/C++ files to
/// import only the header for compile-time safety across different linking configurations.
/// Methods are called dynamically from Objective-C using runtime resolution.
@objc(ReactInlineMessageView)
class ReactInlineMessageView: NSObject {
    private weak var eventEmitter: AnyObject?
    private let contentView: InlineMessageBridgeView = .init()

    @objc
    init(containerView: UIView) {
        super.init()
        contentView.attachToParent(parent: containerView, delegate: self)
    }

    @objc
    func setEventEmitter(_ eventEmitter: AnyObject?) {
        self.eventEmitter = eventEmitter
    }

    @objc
    func setElementId(_ elementId: String) {
        // Set element ID on the prepared content view
        contentView.elementId = elementId
    }

    @objc
    func setupForReuse() {
        contentView.onViewAttached()
    }

    @objc
    func prepareForRecycle() {
        // Remove content view for reuse, cleaning up observers and releasing resources
        contentView.onViewDetached()
    }

    @objc
    func updateLayout(_ boundsValue: NSValue) {
        let bounds = boundsValue.cgRectValue
        contentView.frame = bounds
        contentView.setNeedsLayout()
        contentView.layoutIfNeeded()
    }

    // MARK: - Event Emission Helper

    private func emitEvent(_ selectorName: String, payload: [String: Any]) {
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

    private func sendOnSizeChangeEvent(width: Double = 0, height: Double) {
        let duration = 200.0
        var payload: [String: Any] = [
            "height": height,
            "duration": duration
        ]

        // Only include positive width values as rendering requires valid width to calculate layout size
        if width > 0 {
            payload["width"] = width
        }

        emitEvent("emitOnSizeChangeEvent:", payload: payload)
    }

    private func sendOnStateChangeEvent(state: InlineInAppMessageStateEvent) {
        let payload: [String: Any] = [
            "state": state.stringValue
        ]

        emitEvent("emitOnStateChangeEvent:", payload: payload)
    }
}

extension ReactInlineMessageView: InlineMessageBridgeViewDelegate {
    func onActionClick(message: CioMessagingInApp.InAppMessage, actionValue: String, actionName: String) -> Bool {
        // TODO: Implement later
        false
    }

    func onMessageSizeChanged(width: CGFloat, height: CGFloat) {
        sendOnSizeChangeEvent(width: width, height: height)
    }

    func onNoMessageToDisplay() {
        sendOnStateChangeEvent(state: .noMessageToDisplay)
    }

    func onStartLoading(onComplete: @escaping () -> Void) {
        sendOnStateChangeEvent(state: .loadingStarted)
        onComplete()
    }

    func onFinishLoading() {
        sendOnStateChangeEvent(state: .loadingFinished)
    }
}
