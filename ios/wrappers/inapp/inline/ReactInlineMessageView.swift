import CioMessagingInApp
import Foundation
import UIKit

/// React Native wrapper for inline message display with content view lifecycle management
@objc(ReactInlineMessageView)
class ReactInlineMessageView: NSObject, ReactInlineMessageViewProtocol {
    private weak var eventEmitter: ReactInlineMessageEventEmitterProtocol?
    private let contentView: InlineMessageBridgeView = .init()

    @objc
    init(containerView: UIView) {
        super.init()
        contentView.attachToParent(parent: containerView, delegate: self)
    }

    @objc
    func setEventEmitter(_ eventEmitter: ReactInlineMessageEventEmitterProtocol?) {
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

    private func sendOnSizeChangeEvent(width: Double = 0, height: Double) {
        let duration = 300.0
        var payload: [String: Any] = [
            "height": height,
            "duration": duration
        ]

        // Only include positive width values as rendering requires valid width to calculate layout size
        if width > 0 {
            payload["width"] = width
        }

        eventEmitter?.emitOnSizeChangeEvent(payload as NSDictionary)
    }

    private func sendOnStateChangeEvent(state: InlineInAppMessageStateEvent) {
        let payload: [String: Any] = [
            "state": state.stringValue
        ]

        eventEmitter?.emitOnStateChangeEvent(payload as NSDictionary)
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
