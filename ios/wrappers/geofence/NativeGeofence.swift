#if CIO_GEOFENCE_ENABLED
import CioLocationGeofence

/// Registers the optional geofence module with the native iOS SDK.
///
/// Geofence has no app-facing methods — it runs automatically once registered — so this
/// only parses the opt-in config and builds the module. The reference to `GeofenceModule`
/// is isolated here so it is only compiled when the geofence subspec is installed. Geofence
/// depends on the location module, which the caller registers alongside it.
@objc(NativeCustomerIOGeofence)
public class NativeGeofence: NSObject {

    /// Returns a `GeofenceModule` when the app opts into geofence via the `geofence` config.
    /// Geofence runs automatically once registered and has no options yet.
    static func module(from config: [String: Any]) -> GeofenceModule? {
        guard config["geofence"] != nil else { return nil }
        return GeofenceModule()
    }
}
#endif
