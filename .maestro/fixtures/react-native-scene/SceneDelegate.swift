import React
import ReactAppDependencyProvider
import React_RCTAppDelegate
import UIKit
import customerio_reactnative

class SceneDelegate: RCTDefaultReactNativeFactoryDelegate, UIWindowSceneDelegate {
    private static let launchModeKey = "CioSceneE2EMode"
    private static let persistedModeKey = "CioSceneE2EPersistedMode"

    var window: UIWindow?
    var reactNativeFactory: RCTReactNativeFactory?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }

        if usesAcknowledgedHandler {
            NativeCustomerIO.configureAcknowledgedSceneDeepLinkRouting()
        } else {
            NativeCustomerIO.configureSceneDeepLinkRouting()
        }
        dependencyProvider = RCTAppDependencyProvider()
        reactNativeFactory = RCTReactNativeFactory(delegate: self)
        window = UIWindow(windowScene: windowScene)
        reactNativeFactory?.startReactNative(
            withModuleName: "CioRnSceneHost",
            in: window,
            launchOptions: NativeLiveActivities.reactNativeLaunchOptions(
                from: connectionOptions
            )
        )
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        for context in URLContexts {
            NativeLiveActivities.handleAndRouteWidgetUrl(context.url)
        }
    }

    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        RCTLinkingManager.scene(scene, continue: userActivity)
    }

    override func bundleURL() -> URL? {
        Bundle.main.url(forResource: "main", withExtension: "jsbundle")
    }

    private var usesAcknowledgedHandler: Bool {
        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains(Self.launchModeKey) || arguments.contains("-\(Self.launchModeKey)"),
           let mode = UserDefaults.standard.string(forKey: Self.launchModeKey)
        {
            UserDefaults.standard.set(mode, forKey: Self.persistedModeKey)
        }

        return UserDefaults.standard.string(forKey: Self.persistedModeKey) != "linking"
    }
}
