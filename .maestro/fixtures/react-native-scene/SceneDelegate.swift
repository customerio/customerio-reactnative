import React
import ReactAppDependencyProvider
import React_RCTAppDelegate
import UIKit
import customerio_reactnative

class SceneDelegate: RCTDefaultReactNativeFactoryDelegate, UIWindowSceneDelegate {
    var window: UIWindow?
    var reactNativeFactory: RCTReactNativeFactory?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }

        NativeCustomerIO.configureSceneDeepLinkRouting()
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
}
