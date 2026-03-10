#if CIO_LOCATION_ENABLED
import CioDataPipelines
import CioLocation
import CoreLocation

@objc(NativeCustomerIOLocation)
public class NativeLocation: NSObject {

    /// Parses the root config and returns a `LocationModule` if location config is present.
    /// Keeps config parsing within the location module.
    static func module(from config: [String: Any]) -> LocationModule? {
        guard let locationConfig = config["location"] as? [String: Any] else { return nil }
        let trackingModeValue = locationConfig["trackingMode"] as? String
        let mode: LocationTrackingMode
        switch trackingModeValue?.uppercased() {
        case "OFF":
            mode = .off
        case "ON_APP_START":
            mode = .onAppStart
        default:
            mode = .manual
        }
        return LocationModule(config: LocationConfig(mode: mode))
    }

    @objc
    func setLastKnownLocation(_ latitude: Double, longitude: Double) {
        let location = CLLocation(latitude: latitude, longitude: longitude)
        CustomerIO.location.setLastKnownLocation(location)
    }

    @objc
    func requestLocationUpdate() {
        CustomerIO.location.requestLocationUpdate()
    }
}
#endif
