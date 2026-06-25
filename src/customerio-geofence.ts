/**
 * Public entry point for the optional Geofence module.
 *
 * Geofence runs automatically once enabled — there are no app-facing methods yet.
 * Apps opt in by passing a `geofence` config to `initialize` and enabling the module
 * at build time: set `customerio_geofence_enabled=true` in `gradle.properties` (Android)
 * or add the `geofence` subspec to your Podfile (iOS). Enabling geofence also enables
 * the Location module, which geofence depends on.
 *
 * @public
 */
export class CustomerIOGeofence {}
