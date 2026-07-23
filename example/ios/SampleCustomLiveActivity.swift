#if os(iOS)
import ActivityKit
import CioLiveActivities
import Foundation
import React

/// Sample **app-owned** React Native native module for a custom iOS Live Activity.
///
/// iOS custom activity types can't be data-driven across the Customer.io wrapper bridge (they need
/// an app-declared `ActivityAttributes` + Widget Extension), so the sample app ships this module
/// instead. It holds its own `LiveActivitiesModule` — separate from the one the wrapper creates for
/// the built-in templates — registered for ``RideshareAttributes``. The SDK still mints ids, sends
/// push tokens, and reports start/update/end lifecycle events for the type.
///
/// This mirrors the wrapper's `ios/wrappers/liveactivities/NativeLiveActivities.swift`: the generic
/// `start` returns a `CIOLiveActivity<Attributes>` handle that can't cross the bridge, so we keep a
/// per-id box of closures that capture the concrete handle for later update/end.
@objc(SampleCustomLiveActivity)
class SampleCustomLiveActivity: NSObject {
    private static let rideshareIdentifier = "io.customer.livenotifications.custom.rideshare"

    private static var module: LiveActivitiesModule?

    private struct ActivityBox {
        let update: (_ status: String, _ etaMinutes: Int) async -> Void
        let end: () async -> Void
    }

    private static var activities: [String: ActivityBox] = [:]
    private static let lock = NSLock()

    @available(iOS 16.2, *)
    private static func sharedModule() -> LiveActivitiesModule {
        if let module { return module }
        let created = LiveActivitiesModule.initialize(
            LiveActivityConfigBuilder()
                .register(RideshareAttributes.self, identifier: rideshareIdentifier)
                .build()
        )
        module = created
        return created
    }

    @objc(startRideshare:status:eta:resolve:reject:)
    func startRideshare(
        _ driverName: String,
        status: String,
        eta: NSNumber,
        resolve: @escaping RCTPromiseResolveBlock,
        reject: @escaping RCTPromiseRejectBlock
    ) {
        guard #available(iOS 16.2, *) else {
            return reject("live_activity_unavailable", "Live Activities require iOS 16.2+", nil)
        }
        do {
            let handle = try Self.sharedModule().start(
                RideshareAttributes(driverName: driverName),
                contentState: RideshareAttributes.ContentState(status: status, etaMinutes: eta.intValue)
            )
            Self.store(handle: handle)
            resolve(handle.id)
        } catch {
            reject("live_activity_start_failed", error.localizedDescription, error)
        }
    }

    @objc(updateRideshare:status:eta:resolve:reject:)
    func updateRideshare(
        _ activityId: String,
        status: String,
        eta: NSNumber,
        resolve: @escaping RCTPromiseResolveBlock,
        reject: @escaping RCTPromiseRejectBlock
    ) {
        Self.lock.lock()
        let box = Self.activities[activityId]
        Self.lock.unlock()
        guard let box else {
            return reject("live_activity_update_failed", "No rideshare activity for id \(activityId)", nil)
        }
        Task {
            await box.update(status, eta.intValue)
            resolve(nil)
        }
    }

    @objc(endRideshare:resolve:reject:)
    func endRideshare(
        _ activityId: String,
        resolve: @escaping RCTPromiseResolveBlock,
        reject _: @escaping RCTPromiseRejectBlock
    ) {
        Self.lock.lock()
        let box = Self.activities.removeValue(forKey: activityId)
        Self.lock.unlock()
        // Unknown/already-ended id is idempotent success.
        guard let box else { return resolve(nil) }
        Task {
            await box.end()
            resolve(nil)
        }
    }

    @available(iOS 16.2, *)
    private static func store(handle: CIOLiveActivity<RideshareAttributes>) {
        let box = ActivityBox(
            update: { status, eta in
                await handle.update(RideshareAttributes.ContentState(status: status, etaMinutes: eta))
            },
            end: { await handle.end() }
        )
        lock.lock()
        activities[handle.id] = box
        lock.unlock()
    }

    @objc
    static func requiresMainQueueSetup() -> Bool {
        false
    }
}
#endif
