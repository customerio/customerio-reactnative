import { type TurboModule } from 'react-native';
import {
  default as NativeModule,
  type Spec as CodegenSpec,
} from './specs/modules/NativeCustomerIOLocation';

/**
 * Ensures all methods defined in codegen spec are implemented by the public module
 *
 * @internal
 */
interface NativeLocationSpec extends Omit<CodegenSpec, keyof TurboModule> {}

// Location is an optional module — NativeModule may be null when location is not enabled.
// Methods silently no-op when the native module is unavailable.
const withNativeModule = (fn: (native: CodegenSpec) => void): void => {
  if (NativeModule) {
    fn(NativeModule);
  }
};

/** @public */
export class CustomerIOLocation implements NativeLocationSpec {
  /**
   * Sets the last known location from the host app's existing location system.
   * Use this when your app already manages location and you want to send that data
   * to Customer.io without the SDK managing location permissions directly.
   *
   * @param latitude - Latitude in degrees, must be between -90 and 90
   * @param longitude - Longitude in degrees, must be between -180 and 180
   */
  setLastKnownLocation(latitude: number, longitude: number): void {
    return withNativeModule((native) =>
      native.setLastKnownLocation(latitude, longitude)
    );
  }

  /**
   * Requests a single location update and sends the result to Customer.io.
   * No-ops if location tracking is disabled or permission is not granted.
   *
   * The SDK does not request location permission. The host app must request
   * runtime permissions and only call this when permission is granted.
   */
  requestLocationUpdate(): void {
    return withNativeModule((native) => native.requestLocationUpdate());
  }
}
