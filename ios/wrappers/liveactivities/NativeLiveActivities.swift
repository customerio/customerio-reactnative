#if CIO_LIVEACTIVITIES_ENABLED
import ActivityKit
import CioDataPipelines
import CioLiveActivities
import CioLiveActivities_Attributes
import CioLiveActivities_Templates
import Foundation

@objc(NativeCustomerIOLiveActivities)
public class NativeLiveActivities: NSObject {
    /// The held Live Activities module (not a singleton in the native SDK), created during SDK init.
    private static var module: LiveActivitiesModule?

    /// Type-erased handles keyed by activity id. The native `start` returns a generic
    /// `CIOLiveActivity<Attributes>` that can't cross the bridge, so we keep closures that capture
    /// the concrete handle and rebuild its content-state from a JS map on update.
    private struct ActivityBox {
        let update: ([String: Any]) async throws -> Void
        let end: () async -> Void
    }

    private static var activities: [String: ActivityBox] = [:]
    private static let lock = NSLock()

    // MARK: - Init from SDK config

    /// Initialize the Live Activities module from the SDK config's `liveActivities` key. Registers
    /// the enabled built-in template attribute types so `start` can request them.
    static func initializeModule(from config: [String: Any]) {
        guard let laConfig = config["liveActivities"] as? [String: Any] else { return }
        guard #available(iOS 16.2, *) else { return }
        let templates = (laConfig["templates"] as? [String]) ?? []
        var builder = LiveActivityConfigBuilder()
        if templates.contains("segments") {
            builder = builder.register(CIOSegmentsAttributes.self)
        }
        if templates.contains("countdownTimer") {
            builder = builder.register(CIOCountdownTimerAttributes.self)
        }
        module = LiveActivitiesModule.initialize(builder.build())
    }

    // MARK: - Bridge methods

    @objc(start:resolve:reject:)
    public func start(
        _ payload: NSDictionary,
        resolve: @escaping RCTPromiseResolveBlock,
        reject: @escaping RCTPromiseRejectBlock
    ) {
        guard #available(iOS 16.2, *), let module = Self.module else {
            return reject(Self.unavailableCode, Self.unavailableMessage, nil)
        }
        guard let map = payload as? [String: Any], let type = map["type"] as? String else {
            return reject("live_activity_start_failed", "payload.type is required", nil)
        }
        do {
            let id: String
            switch type {
            case "segments":
                let handle = try module.start(
                    CIOSegmentsAttributes(header: map["header"] as? String ?? ""),
                    contentState: Self.segmentsState(from: map)
                )
                Self.store(handle: handle, contentBuilder: Self.segmentsState)
                id = handle.id
            case "countdownTimer":
                let handle = try module.start(
                    CIOCountdownTimerAttributes(header: map["header"] as? String ?? ""),
                    contentState: Self.countdownState(from: map)
                )
                Self.store(handle: handle, contentBuilder: Self.countdownState)
                id = handle.id
            default:
                return reject("live_activity_start_failed", "Unknown live activity template type: \(type)", nil)
            }
            resolve(id)
        } catch {
            reject("live_activity_start_failed", error.localizedDescription, error)
        }
    }

    @objc(update:payload:resolve:reject:)
    public func update(
        _ activityId: String,
        payload: NSDictionary,
        resolve: @escaping RCTPromiseResolveBlock,
        reject: @escaping RCTPromiseRejectBlock
    ) {
        Self.lock.lock()
        let box = Self.activities[activityId]
        Self.lock.unlock()
        guard let box else {
            return reject("live_activity_update_failed", "No live activity found for id \(activityId)", nil)
        }
        guard let map = payload as? [String: Any] else {
            return reject("live_activity_update_failed", "payload is required", nil)
        }
        Task {
            do {
                try await box.update(map)
                resolve(nil)
            } catch {
                reject("live_activity_update_failed", error.localizedDescription, error)
            }
        }
    }

    @objc(end:resolve:reject:)
    public func end(
        _ activityId: String,
        resolve: @escaping RCTPromiseResolveBlock,
        reject _: @escaping RCTPromiseRejectBlock
    ) {
        Self.lock.lock()
        let box = Self.activities.removeValue(forKey: activityId)
        Self.lock.unlock()
        // Unknown/already-ended id is treated as success (idempotent end).
        guard let box else { return resolve(nil) }
        Task {
            await box.end()
            resolve(nil)
        }
    }

    @objc(startCustom:payload:resolve:reject:)
    public func startCustom(
        _: String,
        payload _: NSDictionary,
        resolve _: @escaping RCTPromiseResolveBlock,
        reject: @escaping RCTPromiseRejectBlock
    ) {
        // Custom activity types on iOS require a native Widget Extension + ActivityAttributes and an
        // `adopt(_:)` call; they cannot be data-driven across the bridge.
        reject(
            "live_activity_custom_unsupported_ios",
            "Custom live activity types are not supported from JavaScript on iOS. Use a native Widget Extension and adopt().",
            nil
        )
    }

    /// Report an `opened` metric when the app is opened from a tapped Live Activity.
    ///
    /// Not exposed to JavaScript: a Live Activity tap arrives through the app's native URL/scene
    /// entry point, so call this from there (see the sample app's `AppDelegate`). Returns `true`
    /// if `url` matched a Customer.io-tracked activity's deep link.
    @discardableResult
    public static func reportDeepLinkOpen(_ url: URL) -> Bool {
        module?.handleDeepLinkOpen(url) ?? false
    }

    // MARK: - Helpers

    @available(iOS 16.2, *)
    private static func store<A: ActivityAttributes>(
        handle: CIOLiveActivity<A>,
        contentBuilder: @escaping ([String: Any]) throws -> A.ContentState
    ) {
        let box = ActivityBox(
            update: { map in await handle.update(try contentBuilder(map)) },
            end: { await handle.end() }
        )
        lock.lock()
        activities[handle.id] = box
        lock.unlock()
    }

    @available(iOS 16.2, *)
    private static func segmentsState(from map: [String: Any]) throws -> CIOSegmentsAttributes.ContentState {
        CIOSegmentsAttributes.ContentState(
            status: map["status"] as? String ?? "",
            substatus: map["substatus"] as? String,
            segmentsTotal: intValue(map["segmentsTotal"]),
            segmentsComplete: intValue(map["segmentsComplete"]),
            trailingText: map["trailingText"] as? String
        )
    }

    @available(iOS 16.2, *)
    private static func countdownState(from map: [String: Any]) throws -> CIOCountdownTimerAttributes.ContentState {
        var endTime: EpochSecondsDate?
        if let seconds = map["endTime"] as? NSNumber {
            endTime = EpochSecondsDate(Date(timeIntervalSince1970: seconds.doubleValue))
        }
        return CIOCountdownTimerAttributes.ContentState(
            title: map["title"] as? String ?? "",
            statusMessage: map["statusMessage"] as? String,
            endTime: endTime
        )
    }

    private static func intValue(_ any: Any?) -> Int {
        (any as? NSNumber)?.intValue ?? 0
    }

    private static let unavailableCode = "live_activity_module_unavailable"
    private static let unavailableMessage =
        "Live Activities are unavailable. Enable live activity templates in the SDK config and add the widget extension."
}
#endif
