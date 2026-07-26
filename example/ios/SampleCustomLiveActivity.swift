#if os(iOS)
import ActivityKit
import CioDataPipelines
import CioLiveActivities
import Foundation
import React

/// Sample **app-owned** React Native native module for a custom iOS Live Activity.
///
/// iOS custom activity types can't be data-driven across the Customer.io wrapper bridge (they need
/// an app-declared `ActivityAttributes` + Widget Extension), so the sample app ships this module
/// instead. The app requests the activity itself through ActivityKit and hands it to
/// ``CustomerIO/liveActivities`` via `adopt(_:)`, which returns a handle whose update/end report
/// lifecycle events.
///
/// Note `adopt` intentionally does not report a `start` event — reporting one requires the type to
/// be registered on the SDK's Live Activities module, and only a Swift metatype can do that, which
/// can't cross the bridge from JavaScript.
///
/// This mirrors the wrapper's `ios/wrappers/liveactivities/NativeLiveActivities.swift`: the generic
/// `start` returns a `CIOLiveActivity<Attributes>` handle that can't cross the bridge, so we keep a
/// per-id box of closures that capture the concrete handle for later update/end.
@objc(SampleCustomLiveActivity)
class SampleCustomLiveActivity: NSObject {
    private struct ActivityBox {
        let update: (_ status: String, _ etaMinutes: Int) async -> Void
        let end: () async -> Void
    }

    private static var activities: [String: ActivityBox] = [:]
    private static let lock = NSLock()

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
            let activity = try Activity.request(
                attributes: RideshareAttributes(driverName: driverName),
                content: ActivityContent(
                    state: RideshareAttributes.ContentState(status: status, etaMinutes: eta.intValue),
                    staleDate: nil
                ),
                pushType: nil
            )
            guard let handle = CustomerIO.liveActivities.adopt(activity) else {
                return reject(
                    "live_activity_module_unavailable",
                    "Customer.io Live Activities are not initialized. Initialize the SDK first.",
                    nil
                )
            }
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
