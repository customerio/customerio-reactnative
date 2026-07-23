import CioLiveActivities_Attributes
import CioLiveActivities_Templates
import SwiftUI
import WidgetKit

// Renders the Customer.io built-in Live Activity templates. The SwiftUI lives in the SDK, so this
// widget bundle is all the app needs. Add more `CIO…LiveActivity()` entries as templates ship.
@main
struct LiveActivityWidgetBundle: WidgetBundle {
    var body: some Widget {
        CIOSegmentsLiveActivity()
        CIOCountdownTimerLiveActivity()
        // App-defined custom template (rendered by the app, not the SDK).
        RideshareLiveActivity()
    }
}
