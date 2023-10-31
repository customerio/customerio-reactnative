import UIKit

public enum MessagePosition: String {
    case top
    case center
    case bottom
}

class ModalViewManager {
    var window: UIWindow!
    var viewController: GistModalViewController!
    var position: MessagePosition

    init(gistView: GistView, position: MessagePosition) {
        self.viewController = GistModalViewController()
        viewController.gistView = gistView
        viewController.setup(position: position)
        self.position = position
    }

    func showModalView(completionHandler: @escaping () -> Void) {
        viewController.view.isHidden = true
        window = getUIWindow()
        window.rootViewController = viewController
        window.isHidden = false
        var finalPosition: CGFloat = 0

        switch position {
        case .top:
            viewController.view.center.y -= viewController.view.bounds.height
            finalPosition = viewController.view.center.y + viewController.view.bounds.height
        case .center:
            viewController.view.center.y += viewController.view.bounds.height
            finalPosition = viewController.view.center.y - viewController.view.bounds.height
        case .bottom:
            viewController.view.center.y += viewController.view.bounds.height
            finalPosition = viewController.view.center.y - viewController.view.bounds.height
        }

        UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseIn], animations: {
            self.viewController.view.center.y = finalPosition
        }, completion: { _ in
            UIView.animate(withDuration: 0.1, delay: 0, options: [.curveEaseIn], animations: {
                self.viewController.view.backgroundColor = UIColor.black.withAlphaComponent(0.2)
            }, completion: nil)
            completionHandler()
        })

        viewController.view.isHidden = false
    }

    func dismissModalView(completionHandler: @escaping () -> Void) {
        var finalPosition: CGFloat = 0
        switch position {
        case .top:
            finalPosition = viewController.view.center.y - viewController.view.bounds.height
        case .center:
            finalPosition = viewController.view.center.y + viewController.view.bounds.height
        case .bottom:
            finalPosition = viewController.view.center.y + viewController.view.bounds.height
        }

        UIView.animate(withDuration: 0.1, delay: 0, options: [.curveEaseIn], animations: {
            self.viewController.view.backgroundColor = UIColor.black.withAlphaComponent(0)
        }, completion: { _ in
            UIView.animate(withDuration: 0.1, delay: 0, options: [.curveEaseIn], animations: {
                self.viewController.view.center.y = finalPosition
            }, completion: { _ in
                self.window?.isHidden = false
                self.viewController.removeFromParent()
                self.window = nil
                completionHandler()
            })
        })
    }

    func getUIWindow() -> UIWindow {
        var modalWindow = UIWindow(frame: UIScreen.main.bounds)
        if #available(iOS 13.0, *) {
            for connectedScene in UIApplication.shared.connectedScenes
                where connectedScene.activationState == .foregroundActive {
                if let windowScene = connectedScene as? UIWindowScene {
                    modalWindow = UIWindow(windowScene: windowScene)
                }
            }
        }
        modalWindow.windowLevel = .normal
        return modalWindow
    }
}
