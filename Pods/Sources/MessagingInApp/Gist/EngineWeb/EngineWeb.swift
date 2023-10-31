import Foundation
import UIKit
import WebKit

public protocol EngineWebDelegate: AnyObject {
    func bootstrapped()
    func tap(name: String, action: String, system: Bool)
    func routeChanged(newRoute: String)
    func routeError(route: String)
    func routeLoaded(route: String)
    func sizeChanged(width: CGFloat, height: CGFloat)
    func error()
}

public class EngineWeb: NSObject {
    private var _currentRoute = ""
    private var _timeoutTimer: Timer?
    private var _elapsedTimer = ElapsedTimer()

    public weak var delegate: EngineWebDelegate?
    var webView = WKWebView()

    public var view: UIView {
        webView
    }

    public private(set) var currentRoute: String {
        get {
            _currentRoute
        }
        set {
            _currentRoute = newValue
        }
    }

    init(configuration: EngineWebConfiguration) {
        super.init()

        _elapsedTimer.start(title: "Engine render for message: \(configuration.messageId)")

        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.navigationDelegate = self
        webView.isOpaque = false
        webView.backgroundColor = UIColor.clear
        webView.scrollView.backgroundColor = UIColor.clear

        let js = "window.parent.postMessage = function(message) {webkit.messageHandlers.gist.postMessage(message)}"
        let messageHandlerScript = WKUserScript(source: js, injectionTime: .atDocumentEnd, forMainFrameOnly: false)

        webView.configuration.userContentController.add(self, name: "gist")
        webView.configuration.userContentController.addUserScript(messageHandlerScript)

        if #available(iOS 11.0, *) {
            webView.scrollView.contentInsetAdjustmentBehavior = .never
        }

        if let jsonData = try? JSONEncoder().encode(configuration),
           let jsonString = String(data: jsonData, encoding: .utf8),
           let options = jsonString.data(using: .utf8)?.base64EncodedString()
           .addingPercentEncoding(withAllowedCharacters: .alphanumerics) {
            let url = "\(Settings.Network.renderer)/index.html?options=\(options)"
            Logger.instance.info(message: "Loading URL: \(url)")
            if let link = URL(string: url) {
                self._timeoutTimer = Timer.scheduledTimer(
                    timeInterval: 5.0,
                    target: self,
                    selector: #selector(forcedTimeout),
                    userInfo: nil,
                    repeats: false
                )
                let request = URLRequest(url: link)
                webView.load(request)
            }
        }
    }

    public func cleanEngineWeb() {
        webView.removeFromSuperview()
        webView.configuration.userContentController.removeAllUserScripts()
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "gist")
    }

    @objc
    func forcedTimeout() {
        Logger.instance.info(message: "Timeout triggered, triggering message error.")
        delegate?.error()
    }
}

// swiftlint:disable cyclomatic_complexity
extension EngineWeb: WKScriptMessageHandler {
    public func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        guard let dict = message.body as? [String: AnyObject],
              let eventProperties = dict["gist"] as? [String: AnyObject],
              let method = eventProperties["method"] as? String,
              let engineEventMethod = EngineEvent(rawValue: method)
        else {
            return
        }

        switch engineEventMethod {
        case .bootstrapped:
            _timeoutTimer?.invalidate()
            delegate?.bootstrapped()
        case .routeLoaded:
            _elapsedTimer.end()
            if let route = EngineEventHandler.getRouteLoadedProperties(properties: eventProperties) {
                delegate?.routeLoaded(route: route)
            }
        case .routeChanged:
            if let route = EngineEventHandler.getRouteChangedProperties(properties: eventProperties) {
                _elapsedTimer.start(title: "Engine render for message: \(route)")
                delegate?.routeChanged(newRoute: route)
            }
        case .routeError:
            if let route = EngineEventHandler.getRouteErrorProperties(properties: eventProperties) {
                delegate?.routeError(route: route)
            }
        case .sizeChanged:
            if let size = EngineEventHandler.getSizeProperties(properties: eventProperties) {
                delegate?.sizeChanged(width: size.width, height: size.height)
            }
        case .tap:
            if let tapProperties = EngineEventHandler.getTapProperties(properties: eventProperties) {
                delegate?.tap(name: tapProperties.name, action: tapProperties.action, system: tapProperties.system)
            }
        case .error:
            delegate?.error()
        }
    }
}

// swiftlint:enable cyclomatic_complexity

extension EngineWeb: WKNavigationDelegate {
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {}

    public func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        delegate?.error()
    }

    public func webView(
        _ webView: WKWebView,
        didFail navigation: WKNavigation!,
        withError error: Error
    ) {
        delegate?.error()
    }

    public func webView(
        _ webView: WKWebView,
        didFailProvisionalNavigation navigation: WKNavigation!,
        withError error: Error
    ) {
        delegate?.error()
    }
}
