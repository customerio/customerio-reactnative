import Foundation
import UIKit

public class Gist: GistDelegate {
    private var messageQueueManager = MessageQueueManager()
    private var messageManagers: [MessageManager] = []
    public var siteId: String = ""
    public var dataCenter: String = ""

    public weak var delegate: GistDelegate?

    public static let shared = Gist()

    public func setup(
        siteId: String,
        dataCenter: String,
        logging: Bool = false,
        env: GistEnvironment = .production
    ) {
        Settings.Environment = env
        self.siteId = siteId
        self.dataCenter = dataCenter
        Logger.instance.enabled = logging
        messageQueueManager.setup()

        // Initialising Gist web with an empty message to fetch fonts and other assets.
        _ = Gist.shared.getMessageView(Message(messageId: ""))
    }

    // MARK: User

    public func setUserToken(_ userToken: String) {
        UserManager().setUserToken(userToken: userToken)
    }

    public func clearUserToken() {
        UserManager().clearUserToken()
        messageQueueManager.clearUserMessagesFromLocalStore()
    }

    // MARK: Route

    public func getCurrentRoute() -> String {
        RouteManager.getCurrentRoute()
    }

    public func setCurrentRoute(_ currentRoute: String) {
        RouteManager.setCurrentRoute(currentRoute)
        messageQueueManager.fetchUserMessagesFromLocalStore()
    }

    public func clearCurrentRoute() {
        RouteManager.clearCurrentRoute()
    }

    // MARK: Message Actions

    public func showMessage(_ message: Message, position: MessagePosition = .center) -> Bool {
        if let messageManager = getModalMessageManager() {
            Logger.instance.info(message: "Message cannot be displayed, \(messageManager.currentMessage.messageId) is being displayed.")
        } else {
            let messageManager = createMessageManager(siteId: siteId, message: message)
            messageManager.showMessage(position: position)
            return true
        }
        return false
    }

    public func getMessageView(_ message: Message) -> GistView {
        let messageManager = createMessageManager(siteId: siteId, message: message)
        return messageManager.getMessageView()
    }

    public func dismissMessage(instanceId: String? = nil, completionHandler: (() -> Void)? = nil) {
        if let id = instanceId, let messageManager = messageManager(instanceId: id) {
            messageManager.removePersistentMessage()
            messageManager.dismissMessage(completionHandler: completionHandler)
        } else {
            getModalMessageManager()?.dismissMessage(completionHandler: completionHandler)
        }
    }

    // MARK: Events

    public func messageShown(message: Message) {
        Logger.instance.debug(message: "Message with route: \(message.messageId) shown")
        if message.gistProperties.persistent != true {
            logMessageView(message: message)
        } else {
            Logger.instance.debug(message: "Persistent message shown, skipping logging view")
        }
        delegate?.messageShown(message: message)
    }

    public func messageDismissed(message: Message) {
        Logger.instance.debug(message: "Message with id: \(message.messageId) dismissed")
        removeMessageManager(instanceId: message.instanceId)
        delegate?.messageDismissed(message: message)
    }

    public func messageError(message: Message) {
        removeMessageManager(instanceId: message.instanceId)
        delegate?.messageError(message: message)
    }

    public func action(message: Message, currentRoute: String, action: String, name: String) {
        delegate?.action(message: message, currentRoute: currentRoute, action: action, name: name)
    }

    public func embedMessage(message: Message, elementId: String) {
        delegate?.embedMessage(message: message, elementId: elementId)
    }

    func logMessageView(message: Message) {
        messageQueueManager.removeMessageFromLocalStore(message: message)
        let userToken = UserManager().getUserToken()
        LogManager(siteId: siteId, dataCenter: dataCenter)
            .logView(message: message, userToken: userToken) { response in
                if case .failure(let error) = response {
                    Logger.instance.error(message: "Failed to log view for message: \(message.messageId) with error: \(error)")
                }
            }
    }

    // Message Manager

    private func createMessageManager(siteId: String, message: Message) -> MessageManager {
        let messageManager = MessageManager(siteId: siteId, message: message)
        messageManager.delegate = self
        messageManagers.append(messageManager)
        return messageManager
    }

    private func getModalMessageManager() -> MessageManager? {
        messageManagers.first(where: { !$0.isMessageEmbed })
    }

    func messageManager(instanceId: String) -> MessageManager? {
        messageManagers.first(where: { $0.currentMessage.instanceId == instanceId })
    }

    func removeMessageManager(instanceId: String) {
        messageManagers.removeAll(where: { $0.currentMessage.instanceId == instanceId })
    }
}
