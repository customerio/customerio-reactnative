// Generated using Sourcery 2.0.3 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT
// swiftlint:disable all

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

        _ = deviceInfo
        countDependenciesResolved += 1

        _ = httpClient
        countDependenciesResolved += 1

        _ = globalDataStore
        countDependenciesResolved += 1

        _ = hooksManager
        countDependenciesResolved += 1

        _ = profileStore
        countDependenciesResolved += 1

        _ = queue
        countDependenciesResolved += 1

        _ = queueQueryRunner
        countDependenciesResolved += 1

        _ = queueRequestManager
        countDependenciesResolved += 1

        _ = queueRunRequest
        countDependenciesResolved += 1

        _ = queueRunner
        countDependenciesResolved += 1

        _ = simpleTimer
        countDependenciesResolved += 1

        _ = singleScheduleTimer
        countDependenciesResolved += 1

        _ = threadUtil
        countDependenciesResolved += 1

        _ = logger
        countDependenciesResolved += 1

        _ = httpRetryPolicy
        countDependenciesResolved += 1

        _ = deviceMetricsGrabber
        countDependenciesResolved += 1

        _ = fileStorage
        countDependenciesResolved += 1

        _ = queueStorage
        countDependenciesResolved += 1

        _ = jsonAdapter
        countDependenciesResolved += 1

        _ = lockManager
        countDependenciesResolved += 1

        _ = queueInventoryMemoryStore
        countDependenciesResolved += 1

        _ = dateUtil
        countDependenciesResolved += 1

        _ = uIKitWrapper
        countDependenciesResolved += 1

        _ = httpRequestRunner
        countDependenciesResolved += 1

        _ = userAgentUtil
        countDependenciesResolved += 1

        _ = keyValueStorage
        countDependenciesResolved += 1

        return countDependenciesResolved
    }

    // DeviceInfo
    public var deviceInfo: DeviceInfo {
        getOverriddenInstance() ??
            newDeviceInfo
    }

    private var newDeviceInfo: DeviceInfo {
        CIODeviceInfo()
    }

    // HttpClient
    public var httpClient: HttpClient {
        getOverriddenInstance() ??
            newHttpClient
    }

    private var newHttpClient: HttpClient {
        CIOHttpClient(sdkConfig: sdkConfig, jsonAdapter: jsonAdapter, httpRequestRunner: httpRequestRunner, globalDataStore: globalDataStore, logger: logger, timer: simpleTimer, retryPolicy: httpRetryPolicy, userAgentUtil: userAgentUtil)
    }

    // GlobalDataStore
    public var globalDataStore: GlobalDataStore {
        getOverriddenInstance() ??
            newGlobalDataStore
    }

    private var newGlobalDataStore: GlobalDataStore {
        CioGlobalDataStore(keyValueStorage: keyValueStorage)
    }

    // HooksManager (singleton)
    public var hooksManager: HooksManager {
        getOverriddenInstance() ??
            sharedHooksManager
    }

    public var sharedHooksManager: HooksManager {
        // Use a DispatchQueue to make singleton thread safe. You must create unique dispatchqueues instead of using 1 shared one or you will get a crash when trying
        // to call DispatchQueue.sync{} while already inside another DispatchQueue.sync{} call.
        DispatchQueue(label: "DIGraph_HooksManager_singleton_access").sync {
            if let overridenDep: HooksManager = getOverriddenInstance() {
                return overridenDep
            }
            let existingSingletonInstance = self.singletons[String(describing: HooksManager.self)] as? HooksManager
            let instance = existingSingletonInstance ?? _get_hooksManager()
            self.singletons[String(describing: HooksManager.self)] = instance
            return instance
        }
    }

    private func _get_hooksManager() -> HooksManager {
        CioHooksManager()
    }

    // ProfileStore
    public var profileStore: ProfileStore {
        getOverriddenInstance() ??
            newProfileStore
    }

    private var newProfileStore: ProfileStore {
        CioProfileStore(keyValueStorage: keyValueStorage)
    }

    // Queue
    public var queue: Queue {
        getOverriddenInstance() ??
            newQueue
    }

    private var newQueue: Queue {
        CioQueue(storage: queueStorage, runRequest: queueRunRequest, jsonAdapter: jsonAdapter, logger: logger, sdkConfig: sdkConfig, queueTimer: singleScheduleTimer, dateUtil: dateUtil)
    }

    // QueueQueryRunner
    var queueQueryRunner: QueueQueryRunner {
        getOverriddenInstance() ??
            newQueueQueryRunner
    }

    private var newQueueQueryRunner: QueueQueryRunner {
        CioQueueQueryRunner(logger: logger)
    }

    // QueueRequestManager (singleton)
    public var queueRequestManager: QueueRequestManager {
        getOverriddenInstance() ??
            sharedQueueRequestManager
    }

    public var sharedQueueRequestManager: QueueRequestManager {
        // Use a DispatchQueue to make singleton thread safe. You must create unique dispatchqueues instead of using 1 shared one or you will get a crash when trying
        // to call DispatchQueue.sync{} while already inside another DispatchQueue.sync{} call.
        DispatchQueue(label: "DIGraph_QueueRequestManager_singleton_access").sync {
            if let overridenDep: QueueRequestManager = getOverriddenInstance() {
                return overridenDep
            }
            let existingSingletonInstance = self.singletons[String(describing: QueueRequestManager.self)] as? QueueRequestManager
            let instance = existingSingletonInstance ?? _get_queueRequestManager()
            self.singletons[String(describing: QueueRequestManager.self)] = instance
            return instance
        }
    }

    private func _get_queueRequestManager() -> QueueRequestManager {
        CioQueueRequestManager()
    }

    // QueueRunRequest
    public var queueRunRequest: QueueRunRequest {
        getOverriddenInstance() ??
            newQueueRunRequest
    }

    private var newQueueRunRequest: QueueRunRequest {
        CioQueueRunRequest(runner: queueRunner, storage: queueStorage, requestManager: queueRequestManager, logger: logger, queryRunner: queueQueryRunner, threadUtil: threadUtil)
    }

    // QueueRunner
    public var queueRunner: QueueRunner {
        getOverriddenInstance() ??
            newQueueRunner
    }

    private var newQueueRunner: QueueRunner {
        CioQueueRunner(jsonAdapter: jsonAdapter, logger: logger, httpClient: httpClient, hooksManager: hooksManager, sdkConfig: sdkConfig)
    }

    // SimpleTimer
    var simpleTimer: SimpleTimer {
        getOverriddenInstance() ??
            newSimpleTimer
    }

    private var newSimpleTimer: SimpleTimer {
        CioSimpleTimer(logger: logger)
    }

    // SingleScheduleTimer (singleton)
    var singleScheduleTimer: SingleScheduleTimer {
        getOverriddenInstance() ??
            sharedSingleScheduleTimer
    }

    var sharedSingleScheduleTimer: SingleScheduleTimer {
        // Use a DispatchQueue to make singleton thread safe. You must create unique dispatchqueues instead of using 1 shared one or you will get a crash when trying
        // to call DispatchQueue.sync{} while already inside another DispatchQueue.sync{} call.
        DispatchQueue(label: "DIGraph_SingleScheduleTimer_singleton_access").sync {
            if let overridenDep: SingleScheduleTimer = getOverriddenInstance() {
                return overridenDep
            }
            let existingSingletonInstance = self.singletons[String(describing: SingleScheduleTimer.self)] as? SingleScheduleTimer
            let instance = existingSingletonInstance ?? _get_singleScheduleTimer()
            self.singletons[String(describing: SingleScheduleTimer.self)] = instance
            return instance
        }
    }

    private func _get_singleScheduleTimer() -> SingleScheduleTimer {
        CioSingleScheduleTimer(timer: simpleTimer)
    }

    // ThreadUtil
    public var threadUtil: ThreadUtil {
        getOverriddenInstance() ??
            newThreadUtil
    }

    private var newThreadUtil: ThreadUtil {
        CioThreadUtil()
    }

    // Logger
    public var logger: Logger {
        getOverriddenInstance() ??
            newLogger
    }

    private var newLogger: Logger {
        ConsoleLogger(sdkConfig: sdkConfig)
    }

    // HttpRetryPolicy
    var httpRetryPolicy: HttpRetryPolicy {
        getOverriddenInstance() ??
            newHttpRetryPolicy
    }

    private var newHttpRetryPolicy: HttpRetryPolicy {
        CustomerIOAPIHttpRetryPolicy()
    }

    // DeviceMetricsGrabber
    var deviceMetricsGrabber: DeviceMetricsGrabber {
        getOverriddenInstance() ??
            newDeviceMetricsGrabber
    }

    private var newDeviceMetricsGrabber: DeviceMetricsGrabber {
        DeviceMetricsGrabberImpl()
    }

    // FileStorage
    public var fileStorage: FileStorage {
        getOverriddenInstance() ??
            newFileStorage
    }

    private var newFileStorage: FileStorage {
        FileManagerFileStorage(sdkConfig: sdkConfig, logger: logger)
    }

    // QueueStorage
    public var queueStorage: QueueStorage {
        getOverriddenInstance() ??
            newQueueStorage
    }

    private var newQueueStorage: QueueStorage {
        FileManagerQueueStorage(fileStorage: fileStorage, jsonAdapter: jsonAdapter, lockManager: lockManager, sdkConfig: sdkConfig, logger: logger, dateUtil: dateUtil, inventoryStore: queueInventoryMemoryStore)
    }

    // JsonAdapter
    public var jsonAdapter: JsonAdapter {
        getOverriddenInstance() ??
            newJsonAdapter
    }

    private var newJsonAdapter: JsonAdapter {
        JsonAdapter(log: logger)
    }

    // LockManager (singleton)
    public var lockManager: LockManager {
        getOverriddenInstance() ??
            sharedLockManager
    }

    public var sharedLockManager: LockManager {
        // Use a DispatchQueue to make singleton thread safe. You must create unique dispatchqueues instead of using 1 shared one or you will get a crash when trying
        // to call DispatchQueue.sync{} while already inside another DispatchQueue.sync{} call.
        DispatchQueue(label: "DIGraph_LockManager_singleton_access").sync {
            if let overridenDep: LockManager = getOverriddenInstance() {
                return overridenDep
            }
            let existingSingletonInstance = self.singletons[String(describing: LockManager.self)] as? LockManager
            let instance = existingSingletonInstance ?? _get_lockManager()
            self.singletons[String(describing: LockManager.self)] = instance
            return instance
        }
    }

    private func _get_lockManager() -> LockManager {
        LockManager()
    }

    // QueueInventoryMemoryStore (singleton)
    var queueInventoryMemoryStore: QueueInventoryMemoryStore {
        getOverriddenInstance() ??
            sharedQueueInventoryMemoryStore
    }

    var sharedQueueInventoryMemoryStore: QueueInventoryMemoryStore {
        // Use a DispatchQueue to make singleton thread safe. You must create unique dispatchqueues instead of using 1 shared one or you will get a crash when trying
        // to call DispatchQueue.sync{} while already inside another DispatchQueue.sync{} call.
        DispatchQueue(label: "DIGraph_QueueInventoryMemoryStore_singleton_access").sync {
            if let overridenDep: QueueInventoryMemoryStore = getOverriddenInstance() {
                return overridenDep
            }
            let existingSingletonInstance = self.singletons[String(describing: QueueInventoryMemoryStore.self)] as? QueueInventoryMemoryStore
            let instance = existingSingletonInstance ?? _get_queueInventoryMemoryStore()
            self.singletons[String(describing: QueueInventoryMemoryStore.self)] = instance
            return instance
        }
    }

    private func _get_queueInventoryMemoryStore() -> QueueInventoryMemoryStore {
        QueueInventoryMemoryStoreImpl()
    }

    // DateUtil
    public var dateUtil: DateUtil {
        getOverriddenInstance() ??
            newDateUtil
    }

    private var newDateUtil: DateUtil {
        SdkDateUtil()
    }

    // UIKitWrapper
    @available(iOSApplicationExtension, unavailable)
    public var uIKitWrapper: UIKitWrapper {
        getOverriddenInstance() ??
            newUIKitWrapper
    }

    @available(iOSApplicationExtension, unavailable)
    private var newUIKitWrapper: UIKitWrapper {
        UIKitWrapperImpl()
    }

    // HttpRequestRunner
    var httpRequestRunner: HttpRequestRunner {
        getOverriddenInstance() ??
            newHttpRequestRunner
    }

    private var newHttpRequestRunner: HttpRequestRunner {
        UrlRequestHttpRequestRunner()
    }

    // UserAgentUtil
    public var userAgentUtil: UserAgentUtil {
        getOverriddenInstance() ??
            newUserAgentUtil
    }

    private var newUserAgentUtil: UserAgentUtil {
        UserAgentUtilImpl(deviceInfo: deviceInfo, sdkConfig: sdkConfig)
    }

    // KeyValueStorage
    public var keyValueStorage: KeyValueStorage {
        getOverriddenInstance() ??
            newKeyValueStorage
    }

    private var newKeyValueStorage: KeyValueStorage {
        UserDefaultsKeyValueStorage(sdkConfig: sdkConfig, deviceMetricsGrabber: deviceMetricsGrabber)
    }
}

// swiftlint:enable all
