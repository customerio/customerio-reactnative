import CioLocation
import CoreLocation

@objc(NativeCustomerIOLocation)
public class NativeLocation: NSObject {

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
