#if CIO_LIVEACTIVITIES_ENABLED
import ActivityKit
import CioDataPipelines
import CioInternalCommon
import CioLiveActivities
import CioLiveActivities_Attributes
import CioLiveActivities_Templates
import Foundation
import UIKit

@objc(NativeCustomerIOLiveActivities)
public class NativeLiveActivities: NSObject {
    /// Reverse-DNS activity type identifiers for the SDK's built-in templates. These are the same
    /// strings the backend sends as `notificationType` and that Android's `LiveNotificationType`
    /// exposes, so JS, both native SDKs, and the wire format share one vocabulary.
    enum TypeIdentifier {
        static let segments = "io.customer.livenotifications.segments"
        static let countdownTimer = "io.customer.livenotifications.countdowntimer"
        /// Discriminator JavaScript sends for the custom template. Not a wire identifier — the
        /// activity is reported under the app's own `liveNotifications.customType`.
        static let custom = "custom"
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

    /// Records an `update`/`end` aimed at an activity this process never started. Not surfaced to
    /// JavaScript — see the call sites — but worth a log, because the same message covers both a
    /// genuine caller mistake and the expected post-restart / push-started cases.
    private static func logUnknownActivity(_ activityId: String, method: String) {
        DIGraphShared.shared.logger.info(
            "Live Activities: \(method) ignored — no activity with id \(activityId) was started by this app session. " +
                "Activities started before an app restart, or started by a push, are not tracked in-process."
        )
    }

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
        // The custom template registers one SDK-owned Swift type under the app's own identifier.
        // That indirection is what lets a JavaScript app have a custom activity at all: the SDK needs
        // a metatype to register and to observe push-to-start for, and a metatype can't cross a bridge.
        let trimmedCustomType = (liveConfig["customType"] as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let customType = (trimmedCustomType?.isEmpty == false) ? trimmedCustomType : nil
        if let customType {
            builder = builder.register(CIOCustomAttributes.self, identifier: customType)
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
                    CIOSegmentsAttributes(header: try Self.requireString(map, "header")),
                    contentState: Self.segmentsState(from: map)
                ) else {
                    return reject(Self.notRegisteredCode, Self.notRegisteredMessage(type), nil)
                }
                Self.store(handle: handle, contentBuilder: Self.segmentsState)
                id = handle.id
            case TypeIdentifier.countdownTimer:
                guard let handle = try CustomerIO.liveActivities.start(
                    CIOCountdownTimerAttributes(header: try Self.requireString(map, "header")),
                    contentState: Self.countdownState(from: map)
                ) else {
                    return reject(Self.notRegisteredCode, Self.notRegisteredMessage(type), nil)
                }
                Self.store(handle: handle, contentBuilder: Self.countdownState)
                id = handle.id
            case TypeIdentifier.custom:
                // No pre-check on the stored identifier: the SDK config can also be built by generated
                // native code that never calls `module(from:)` — the Expo config plugin does exactly
                // that — so a nil stored value doesn't mean the type is unregistered. Attempt the start
                // and let the SDK answer; a nil handle means it genuinely isn't registered.
                guard let handle = try CustomerIO.liveActivities.start(
                    CIOCustomAttributes(),
                    contentState: Self.customState(from: map)
                ) else {
                    return reject(Self.notRegisteredCode, Self.customNotRegisteredMessage, nil)
                }
                Self.store(handle: handle, contentBuilder: Self.customState)
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
        // An unknown id means the update did not happen, so it must not report success. Unlike `end`
        // — where re-ending an already-ended activity is a legitimate no-op — there is nothing
        // idempotent about an update that never applied. Android *does* perform it (it routes the id
        // straight to the native SDK), so resolving here would make the same call report success on
        // both platforms while only one of them did anything.
        guard let box else {
            Self.logUnknownActivity(activityId, method: "update")
            return reject(
                "live_activity_update_failed",
                "No live activity found for id \(activityId). On iOS only activities started in this " +
                    "app session can be updated.",
                nil
            )
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
        let box = Self.activities[activityId]
        Self.lock.unlock()
        // Unknown/already-ended id is treated as success (idempotent end). See `update` for why an
        // unknown id is not an error.
        guard let box else {
            Self.logUnknownActivity(activityId, method: "end")
            return resolve(nil)
        }
        let map = payload as? [String: Any]
        Task {
            do {
                try await box.end(map)
                // Dropped only once the end succeeded. Removing up front would lose the handle on a
                // throw, and the retry would then take the unknown-id path above and report success
                // for an activity still on screen.
                Self.forget(activityId)
                resolve(nil)
            } catch {
                reject("live_activity_end_failed", error.localizedDescription, error)
            }
        }
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

    /// Report an `opened` metric for a tapped Live Activity and route its destination through
    /// React Native Linking. Call this from a scene-based host's URL lifecycle method.
    public static func handleAndRouteWidgetUrl(_ url: URL) {
        guard let routableUrl = handleWidgetUrl(url) else { return }
        CustomerIOReactNativeDeepLinkRouter.route(routableUrl)
    }

    /// Build React Native launch options from a scene connection, reporting a cold Live Activity
    /// tap and replacing Customer.io's internal tracking URL with its destination. This mirrors
    /// React Native 0.88's `RCTConvertConnectionOptionsToLaunchOptions` conversion.
    public static func reactNativeLaunchOptions(
        from connectionOptions: UIScene.ConnectionOptions
    ) -> [UIApplication.LaunchOptionsKey: Any] {
        var launchOptions: [UIApplication.LaunchOptionsKey: Any] = [:]

        if let url = connectionOptions.urlContexts.first?.url,
           let routableUrl = handleWidgetUrl(url)
        {
            launchOptions[.url] = routableUrl
        }

        if let userActivity = connectionOptions.userActivities.first {
            launchOptions[.userActivityDictionary] = [
                UIApplication.LaunchOptionsKey.userActivityType.rawValue: userActivity.activityType,
                "UIApplicationLaunchOptionsUserActivityKey": userActivity,
            ]
        }

        return launchOptions
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

    private static func forget(_ activityId: String) {
        lock.lock()
        activities.removeValue(forKey: activityId)
        lock.unlock()
    }

    /// Thrown for a missing required field so the caller sees a rejected promise naming it, rather
    /// than an activity rendering with a blank line. Matches Android, whose `requireString` /
    /// `requireDouble` already reject — an untyped JavaScript caller should not get a silent
    /// half-rendered card on one platform and an error on the other.
    private struct MissingFieldError: LocalizedError {
        let field: String
        var errorDescription: String? { "\(field) is required" }
    }

    private static func requireString(_ map: [String: Any], _ key: String) throws -> String {
        guard let value = map[key] as? String else { throw MissingFieldError(field: key) }
        return value
    }

    private static func requireInt(_ map: [String: Any], _ key: String) throws -> Int {
        guard let value = map[key] as? NSNumber else { throw MissingFieldError(field: key) }
        return value.intValue
    }

    @available(iOS 16.2, *)
    private static func segmentsState(from map: [String: Any]) throws -> CIOSegmentsAttributes.ContentState {
        CIOSegmentsAttributes.ContentState(
            status: try requireString(map, "status"),
            substatus: map["substatus"] as? String,
            segmentsTotal: try requireInt(map, "segmentsTotal"),
            segmentsComplete: try requireInt(map, "segmentsComplete"),
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
            title: try requireString(map, "title"),
            statusMessage: map["statusMessage"] as? String,
            endTime: endTime
        )
    }

    /// Builds the custom template's content-state from the JS payload's `data` map.
    ///
    /// Values are coerced to strings rather than rejected: JavaScript numbers and booleans arrive as
    /// `NSNumber`, and refusing them would make `{ eta: 5 }` fail for no reason a caller can see.
    /// Anything without a sensible text form is dropped instead of stringifying as gibberish.
    @available(iOS 16.2, *)
    private static func customState(from map: [String: Any]) throws -> CIOCustomAttributes.ContentState {
        let raw = map["data"] as? [String: Any] ?? [:]
        var data: [String: String] = [:]
        for (key, value) in raw {
            switch value {
            case let string as String: data[key] = string
            case let number as NSNumber: data[key] = number.stringValue
            default: continue
            }
        }
        return CIOCustomAttributes.ContentState(data: data)
    }

    private static let unavailableCode = "live_activity_module_unavailable"
    private static let unavailableMessage =
        "Live Activities require iOS 16.2 or later."

    private static let customNotRegisteredMessage =
        "No custom Live Activity type is registered. Set `liveNotifications.customType` in your " +
        "Customer.io SDK config to your own reverse-DNS identifier, and render CIOCustomAttributes " +
        "in your Widget Extension."

    private static let notRegisteredCode = "live_activity_type_not_registered"
    private static func notRegisteredMessage(_ type: String) -> String {
        "Live Activity type '\(type)' is not registered. Add it to `liveNotifications.types` in your " +
            "Customer.io SDK config, and make sure your widget extension renders it."
    }

    private static let unsupportedTypeCode = "live_activity_type_unsupported"
}
#endif
