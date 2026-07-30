import { type TurboModule } from 'react-native';
import {
  default as NativeModule,
  type Spec as CodegenSpec,
} from './specs/modules/NativeCustomerIOGeofence';

/**
 * Ensures all methods defined in codegen spec are implemented by the public module
 *
 * @internal
 */
interface NativeGeofenceSpec extends Omit<CodegenSpec, keyof TurboModule> {}

// Geofence is an optional module — NativeModule may be null when geofence is not enabled.
// Methods silently no-op when the native module is unavailable, with a one-time dev warning.
let hasWarnedNotEnabled = false;
const withNativeModule = (fn: (native: CodegenSpec) => void): void => {
  if (NativeModule) {
    fn(NativeModule);
  } else if (__DEV__ && !hasWarnedNotEnabled) {
    hasWarnedNotEnabled = true;
    console.warn(
      'Customer.io: Geofence module is not enabled. ' +
        'To use geofence features, set customerio_geofence_enabled=true in ' +
        'gradle.properties (Android) or add the geofence subspec to your Podfile (iOS).'
    );
  }
};

/**
 * Public entry point for the optional Geofence module.
 *
 * Geofence runs automatically once enabled. Apps opt in by passing a `geofence` config to
 * `initialize` and enabling the module at build time: set `customerio_geofence_enabled=true`
 * in `gradle.properties` (Android) or add the `geofence` subspec to your Podfile (iOS).
 * Enabling geofence also enables the Location module, which geofence depends on.
 *
 * @public
 */
export class CustomerIOGeofence implements NativeGeofenceSpec {
  /**
   * Requests a one-shot location fix and refreshes the nearby geofence set from it,
   * without sending a location analytics event (unlike
   * `CustomerIO.location.requestLocationUpdate()`) and without caching the fix.
   *
   * Call this after the host app has been granted location permission — the SDK never
   * requests permission itself. It is the primary way to drive geofencing when the module
   * is configured with `MANUAL` location mode; with the default `AUTOMATIC` the SDK acquires
   * location on its own and this only forces an immediate refresh.
   *
   * No-ops if the geofence module is not enabled or a user has not been identified.
   */
  refreshFromCurrentLocation(): void {
    return withNativeModule((native) => native.refreshFromCurrentLocation());
  }
}
