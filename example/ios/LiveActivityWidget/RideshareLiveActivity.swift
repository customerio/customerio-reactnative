#if os(iOS)
import ActivityKit
import SwiftUI
import WidgetKit

/// SwiftUI rendering for the app-defined ``RideshareAttributes`` Live Activity.
///
/// Unlike the Customer.io built-in templates (whose SwiftUI ships in the SDK), a custom activity is
/// rendered entirely by the app. Add it to the widget bundle alongside the built-in templates.
@available(iOS 16.2, *)
struct RideshareLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: RideshareAttributes.self) { context in
            // Lock screen / banner presentation.
            VStack(alignment: .leading, spacing: 4) {
                Text("Rideshare").font(.headline)
                Text(context.attributes.driverName).font(.subheadline)
                Text(context.state.status).font(.body)
                Text("ETA \(context.state.etaMinutes) min").font(.caption).foregroundColor(.secondary)
            }
            .padding()
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Text(context.attributes.driverName)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("\(context.state.etaMinutes) min")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text(context.state.status)
                }
            } compactLeading: {
                Image(systemName: "car.fill")
            } compactTrailing: {
                Text("\(context.state.etaMinutes)m")
            } minimal: {
                Image(systemName: "car.fill")
            }
        }
    }
}
#endif
