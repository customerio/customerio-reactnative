#if CIO_LIVEACTIVITIES_ENABLED
import ActivityKit
import CioDataPipelines
import CioLiveActivities
import CioLiveActivities_Attributes
import CioLiveActivities_Templates
import Foundation

@objc(NativeCustomerIOLiveActivities)
public class NativeLiveActivities: NSObject {
    /// Reverse-DNS activity type identifiers for the SDK's built-in templates. These are the same
    /// strings the backend sends as `notificationType` and that Android's `LiveNotificationType`
    /// exposes, so JS, both native SDKs, and the wire format share one vocabulary.
    enum TypeIdentifier {
        static let segments = "io.customer.livenotifications.segments"
        static let countdownTimer = "io.customer.livenotifications.countdowntimer"
    }

    /// Type-erased handles keyed by activity id. The native `start` returns a generic
    /// `CIOLiveActivity<Attributes>` that can't cross the bridge, so we keep closures that capture
    /// the concrete handle and rebuild its content-state from a JS map on update.
    private struct ActivityBox {
        let update: ([String: Any]) async throws -> Void
        let end: ([String: Any]?) async throws -> Void
    }

    private static var activities: [String: ActivityBox] = [:]
    private static let lock = NSLock()

    // MARK: - Module registration

    /// Build the Live Activities module from the SDK config's `liveNotifications` key, mirroring
    /// ``NativeLocation/module(from:)``. Registers the enabled built-in template attribute types so
    /// `CustomerIO.liveActivities.start` can request them, and so push-to-start tokens register for
    /// them at SDK init.
    ///
    /// Unrecognized type identifiers are ignored: a newer native SDK may ship templates this
    /// wrapper build doesn't know, and that must never break registration of the ones it does.
    static func module(from config: [String: Any]) -> LiveActivitiesModule? {
        guard let liveConfig = config["liveNotifications"] as? [String: Any] else { return nil }
        guard #available(iOS 16.2, *) else { return nil }
        let types = (liveConfig["types"] as? [String]) ?? []
        var builder = LiveActivityConfigBuilder()
        for type in types {
            switch type {
            case TypeIdentifier.segments:
                builder = builder.register(CIOSegmentsAttributes.self)
            case TypeIdentifier.countdownTimer:
                builder = builder.register(CIOCountdownTimerAttributes.self)
            default:
                continue
            }
        }
        return LiveActivitiesModule(config: builder.build())
    }

    // MARK: - Bridge methods

    @objc(start:resolve:reject:)
    public func start(
        _ payload: NSDictionary,
        resolve: @escaping RCTPromiseResolveBlock,
        reject: @escaping RCTPromiseRejectBlock
    ) {
        guard #available(iOS 16.2, *) else {
            return reject(Self.unavailableCode, Self.unavailableMessage, nil)
        }
        guard let map = payload as? [String: Any], let type = map["type"] as? String else {
            return reject("live_activity_start_failed", "payload.type is required", nil)
        }
        do {
            // A nil handle means the module isn't registered or this type wasn't enabled. The
            // native SDK logs and returns nil rather than throwing, so surface it as a rejected
            // promise — never a crash.
            let id: String
            switch type {
            case TypeIdentifier.segments:
                guard let handle = try CustomerIO.liveActivities.start(
                    CIOSegmentsAttributes(header: map["header"] as? String ?? ""),
                    contentState: Self.segmentsState(from: map)
                ) else {
                    return reject(Self.notRegisteredCode, Self.notRegisteredMessage(type), nil)
                }
                Self.store(handle: handle, contentBuilder: Self.segmentsState)
                id = handle.id
            case TypeIdentifier.countdownTimer:
                guard let handle = try CustomerIO.liveActivities.start(
                    CIOCountdownTimerAttributes(header: map["header"] as? String ?? ""),
                    contentState: Self.countdownState(from: map)
                ) else {
                    return reject(Self.notRegisteredCode, Self.notRegisteredMessage(type), nil)
                }
                Self.store(handle: handle, contentBuilder: Self.countdownState)
                id = handle.id
            default:
                // A newer native SDK may know this type even though this wrapper build doesn't.
                // Fail softly so an unrecognized template can never crash the host app.
                return reject(Self.unsupportedTypeCode, "Unsupported Live Activity template: \(type)", nil)
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

    @objc(end:payload:resolve:reject:)
    public func end(
        _ activityId: String,
        payload: NSDictionary?,
        resolve: @escaping RCTPromiseResolveBlock,
        reject: @escaping RCTPromiseRejectBlock
    ) {
        Self.lock.lock()
        let box = Self.activities.removeValue(forKey: activityId)
        Self.lock.unlock()
        // Unknown/already-ended id is treated as success (idempotent end).
        guard let box else { return resolve(nil) }
        let map = payload as? [String: Any]
        Task {
            do {
                try await box.end(map)
                resolve(nil)
            } catch {
                reject("live_activity_end_failed", error.localizedDescription, error)
            }
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

    /// Report an `opened` metric for a tapped Live Activity and return the deep link to route to.
    ///
    /// Not exposed to JavaScript: a Live Activity tap arrives through the app's native URL/scene
    /// entry point, so call this from there (see the sample app's `AppDelegate`).
    ///
    /// - Returns: the customer's redirect URL for a Customer.io widget URL (`nil` when it carries
    ///   none), or `url` unchanged when it isn't a Customer.io URL — so existing routing still
    ///   handles non-CIO links.
    @discardableResult
    public static func handleWidgetUrl(_ url: URL) -> URL? {
        CustomerIO.liveActivities.handleWidgetUrl(url)
    }

    // MARK: - Helpers

    @available(iOS 16.2, *)
    private static func store<A: ActivityAttributes>(
        handle: CIOLiveActivity<A>,
        contentBuilder: @escaping ([String: Any]) throws -> A.ContentState
    ) {
        let box = ActivityBox(
            // ActivityKit keeps the last content-state on screen when `end` is given none, so a
            // final payload is what lets the activity show a terminal state rather than freezing
            // mid-progress.
            update: { map in await handle.update(try contentBuilder(map)) },
            end: { map in await handle.end(try map.map(contentBuilder)) }
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
        "Live Activities require iOS 16.2 or later."

    private static let notRegisteredCode = "live_activity_type_not_registered"
    private static func notRegisteredMessage(_ type: String) -> String {
        "Live Activity type '\(type)' is not registered. Add it to `liveNotifications.types` in your " +
            "Customer.io SDK config, and make sure your widget extension renders it."
    }

    private static let unsupportedTypeCode = "live_activity_type_unsupported"
}
#endif
