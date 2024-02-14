// Generated using Sourcery 2.0.3 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT
// swiftlint:disable all

import CioInternalCommon
import CioTracking
import Foundation

/**
 ######################################################
 Documentation
 ######################################################

 This automatically generated file you are viewing is a dependency injection graph for your app's source code.
 You may be wondering a couple of questions.

 1. How did this file get generated? Answer --> https://github.com/levibostian/Sourcery-DI#how
 2. Why use this dependency injection graph instead of X other solution/tool? Answer --> https://github.com/levibostian/Sourcery-DI#why-use-this-project
 3. How do I add dependencies to this graph file? Follow one of the instructions below:
 * Add a non singleton class: https://github.com/levibostian/Sourcery-DI#add-a-non-singleton-class
 * Add a generic class: https://github.com/levibostian/Sourcery-DI#add-a-generic-class
 * Add a singleton class: https://github.com/levibostian/Sourcery-DI#add-a-singleton-class
 * Add a class from a 3rd party library/SDK: https://github.com/levibostian/Sourcery-DI#add-a-class-from-a-3rd-party
 * Add a `typealias` https://github.com/levibostian/Sourcery-DI#add-a-typealias

 4. How do I get dependencies from the graph in my code?
 ```
 // If you have a class like this:
 class OffRoadWheels {}

 class ViewController: UIViewController {
     // Call the property getter to get your dependency from the graph:
     let wheels = DIGraph.getInstance(siteId: "").offRoadWheels
     // note the name of the property is name of the class with the first letter lowercase.
 }
 ```

 5. How do I use this graph in my test suite?
 ```
 let mockOffRoadWheels = // make a mock of OffRoadWheels class
 DIGraph().override(mockOffRoadWheels, OffRoadWheels.self)
 ```

 Then, when your test function finishes, reset the graph:
 ```
 DIGraph().reset()
 ```

 */

extension DIGraph {
    // call in automated test suite to confirm that all dependnecies able to resolve and not cause runtime exceptions.
    // internal scope so each module can provide their own version of the function with the same name.
    @available(iOSApplicationExtension, unavailable) // some properties could be unavailable to app extensions so this function must also.
    func testDependenciesAbleToResolve() -> Int {
        var countDependenciesResolved = 0

        _ = automaticPushClickHandling
        countDependenciesResolved += 1

        _ = deepLinkUtil
        countDependenciesResolved += 1

        _ = pushEventHandler
        countDependenciesResolved += 1

        _ = pushClickHandler
        countDependenciesResolved += 1

        _ = pushHistory
        countDependenciesResolved += 1

        _ = userNotificationCenter
        countDependenciesResolved += 1

        return countDependenciesResolved
    }

    // AutomaticPushClickHandling
    @available(iOSApplicationExtension, unavailable)
    var automaticPushClickHandling: AutomaticPushClickHandling {
        getOverriddenInstance() ??
            newAutomaticPushClickHandling
    }

    @available(iOSApplicationExtension, unavailable)
    private var newAutomaticPushClickHandling: AutomaticPushClickHandling {
        AutomaticPushClickHandlingImpl(notificationCenterAdapter: userNotificationsFrameworkAdapter, logger: logger)
    }

    // DeepLinkUtil
    @available(iOSApplicationExtension, unavailable)
    var deepLinkUtil: DeepLinkUtil {
        getOverriddenInstance() ??
            newDeepLinkUtil
    }

    @available(iOSApplicationExtension, unavailable)
    private var newDeepLinkUtil: DeepLinkUtil {
        DeepLinkUtilImpl(logger: logger, uiKitWrapper: uIKitWrapper)
    }

    // PushEventHandler
    @available(iOSApplicationExtension, unavailable)
    var pushEventHandler: PushEventHandler {
        getOverriddenInstance() ??
            newPushEventHandler
    }

    @available(iOSApplicationExtension, unavailable)
    private var newPushEventHandler: PushEventHandler {
        IOSPushEventListener(jsonAdapter: jsonAdapter, pushEventHandlerProxy: pushEventHandlerProxy, moduleConfig: messagingPushConfigOptions, pushClickHandler: pushClickHandler, pushHistory: pushHistory, logger: logger)
    }

    // PushClickHandler
    @available(iOSApplicationExtension, unavailable)
    var pushClickHandler: PushClickHandler {
        getOverriddenInstance() ??
            newPushClickHandler
    }

    @available(iOSApplicationExtension, unavailable)
    private var newPushClickHandler: PushClickHandler {
        PushClickHandlerImpl(deepLinkUtil: deepLinkUtil, customerIO: customerIOInstance)
    }

    // PushHistory (singleton)
    var pushHistory: PushHistory {
        getOverriddenInstance() ??
            sharedPushHistory
    }

    var sharedPushHistory: PushHistory {
        // Use a DispatchQueue to make singleton thread safe. You must create unique dispatchqueues instead of using 1 shared one or you will get a crash when trying
        // to call DispatchQueue.sync{} while already inside another DispatchQueue.sync{} call.
        DispatchQueue(label: "DIGraph_PushHistory_singleton_access").sync {
            if let overridenDep: PushHistory = getOverriddenInstance() {
                return overridenDep
            }
            let existingSingletonInstance = self.singletons[String(describing: PushHistory.self)] as? PushHistory
            let instance = existingSingletonInstance ?? _get_pushHistory()
            self.singletons[String(describing: PushHistory.self)] = instance
            return instance
        }
    }

    private func _get_pushHistory() -> PushHistory {
        PushHistoryImpl(lockManager: lockManager)
    }

    // UserNotificationCenter
    var userNotificationCenter: UserNotificationCenter {
        getOverriddenInstance() ??
            newUserNotificationCenter
    }

    private var newUserNotificationCenter: UserNotificationCenter {
        UserNotificationCenterImpl()
    }
}

// swiftlint:enable all
