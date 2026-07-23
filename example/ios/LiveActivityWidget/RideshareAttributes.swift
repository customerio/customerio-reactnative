#if os(iOS)
import ActivityKit
import Foundation

/// App-defined `ActivityAttributes` for the custom "Rideshare" Live Activity.
///
/// This is an app-owned custom type (not a Customer.io built-in template): the app both declares
/// the attributes here and renders them in ``RideshareLiveActivity``. The Customer.io SDK only
/// needs it registered (see `SampleCustomLiveActivity`) to mint ids, push tokens, and report
/// start/update/end lifecycle events.
///
/// This one file must be a member of **both** the app target and the widget extension target so
/// each side compiles against the same type.
@available(iOS 16.2, *)
struct RideshareAttributes: ActivityAttributes {
    /// Dynamic content — replaced on every update.
    public struct ContentState: Codable, Hashable {
        /// Primary status line, e.g. "On the way".
        var status: String
        /// Estimated time of arrival, in minutes.
        var etaMinutes: Int
    }

    /// Static attribute — fixed for the life of the activity.
    var driverName: String
}
#endif
