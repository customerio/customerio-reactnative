#if os(iOS)
import ActivityKit
import CioLiveActivities_Attributes
import SwiftUI
import WidgetKit

/// SwiftUI rendering for the app's custom "rideshare" Live Activity.
///
/// The built-in templates ship their SwiftUI in the SDK; a custom activity is rendered entirely by
/// the app. What the SDK does provide is the attributes *type*: ``CIOCustomAttributes`` carries an
/// untyped `data` map, which is what lets JavaScript start and update this activity without the app
/// defining a Swift type the bridge could never reach.
///
/// The keys read below are the ones the JS screen sends. Every value is a string, so parse whatever
/// you need at render time.
@available(iOS 16.2, *)
struct RideshareLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: CIOCustomAttributes.self) { context in
            // Lock screen / banner presentation.
            VStack(alignment: .leading, spacing: 4) {
                Text("Rideshare").font(.headline)
                Text(context.state.data["driverName"] ?? "").font(.subheadline)
                Text(context.state.data["status"] ?? "").font(.body)
                Text("ETA \(context.state.data["etaMinutes"] ?? "—") min")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            // Required on any custom template: this is what carries the tap URL the SDK
            // reports `opened` from and routes the deep link with. The bundled templates do
            // the same on both their lock screen and Dynamic Island.
            .cioWidgetUrl(context.state.cioMetadata)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Text(context.state.data["driverName"] ?? "")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("\(context.state.data["etaMinutes"] ?? "—") min")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text(context.state.data["status"] ?? "")
                }
            } compactLeading: {
                Image(systemName: "car.fill")
            } compactTrailing: {
                Text("\(context.state.data["etaMinutes"] ?? "")m")
            } minimal: {
                Image(systemName: "car.fill")
            }
            .cioWidgetUrl(context.state.cioMetadata)
        }
    }
}
#endif
