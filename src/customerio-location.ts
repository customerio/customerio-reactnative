import {
  default as NativeModule,
  type Spec as CodegenSpec,
} from './specs/modules/NativeCustomerIOLocation';
import { callNativeModule, ensureNativeModule } from './utils/native-bridge';

const nativeModule = ensureNativeModule(NativeModule);

const withNativeModule = <R>(fn: (native: CodegenSpec) => R): R => {
  return callNativeModule(nativeModule, fn);
};

/** @public */
export class CustomerIOLocation {
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
