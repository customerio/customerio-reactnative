#if CIO_GEOFENCE_ENABLED
import CioDataPipelines
import CioLocationGeofence

/// Registers the optional geofence module with the native iOS SDK and exposes its app-facing
/// methods. The reference to `GeofenceModule` is isolated here so it is only compiled when the
/// geofence subspec is installed. Geofence depends on the location module, which the caller
/// registers alongside it.
@objc(NativeCustomerIOGeofence)
public class NativeGeofence: NSObject {

    /// Returns a `GeofenceModule` when the app opts into geofence via the `geofence` config,
    /// applying the optional `locationMode` (defaults to `.automatic`).
    static func module(from config: [String: Any]) -> GeofenceModule? {
        guard let geofenceConfig = config["geofence"] as? [String: Any] else { return nil }
        let locationModeValue = geofenceConfig["locationMode"] as? String
        let locationMode: GeofenceLocationMode =
            locationModeValue?.uppercased() == "MANUAL" ? .manual : .automatic
        return GeofenceModule(config: GeofenceModuleConfig(locationMode: locationMode))
    }

    @objc
    func refreshFromCurrentLocation() {
        CustomerIO.geofence.refreshFromCurrentLocation()
    }
}
#endif
