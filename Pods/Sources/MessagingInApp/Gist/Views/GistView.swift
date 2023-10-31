import Foundation
import UIKit

public protocol GistViewDelegate: AnyObject {
    func action(message: Message, currentRoute: String, action: String, name: String)
    func sizeChanged(message: Message, width: CGFloat, height: CGFloat)
}

public class GistView: UIView {
    public weak var delegate: GistViewDelegate?
    private var message: Message?

    convenience init(message: Message, engineView: UIView) {
        self.init()
        self.message = message
        addSubview(engineView)
        engineView.autoresizingMask = [.flexibleWidth, .flexibleHeight, .flexibleBottomMargin, .flexibleRightMargin]
    }

    override public func removeFromSuperview() {
        super.removeFromSuperview()
        if let message = message {
            Gist.shared.removeMessageManager(instanceId: message.instanceId)
        }
    }
}
