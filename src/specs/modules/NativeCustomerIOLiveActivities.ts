import { TurboModuleRegistry, type TurboModule } from 'react-native';
import type { UnsafeObject } from 'react-native/Libraries/Types/CodegenTypes';

/**
 * Native module specification for CustomerIO Live Activities React Native SDK
 *
 * Live Activities (iOS) / Live Notifications (Android) let you show a live,
 * updating notification driven by a built-in template (Segments, Countdown Timer)
 * or by a custom type you render yourself.
 *
 * @see NativeCustomerIO.ts for detailed documentation on TurboModule patterns,
 * Codegen compatibility, and type safety approach.
 */

type NativeBridgeObject = UnsafeObject;

export interface Spec extends TurboModule {
  /** Report a Live Activity open and return the destination URL to route. */
  handleWidgetUrl(url: string): Promise<string | null>;
  /** Start an activity. Resolves with the SDK-minted activity id. */
  start(payload: NativeBridgeObject): Promise<string>;
  /** Replace the whole content-state of a running activity. Pass the full desired state. */
  update(activityId: string, payload: NativeBridgeObject): Promise<void>;
  /**
   * End a running activity, optionally rendering a final content-state.
   *
   * `payload` is iOS-only: ActivityKit keeps the last content-state on screen unless a final one
   * is supplied. Android renders its own terminal state, so it ignores the payload.
   */
  end(activityId: string, payload?: NativeBridgeObject): Promise<void>;
}

// Registered unconditionally on both platforms — Android in CustomerIOReactNativePackage, iOS via
// an ObjC bridge that is always compiled. When the Live Activities pods are absent the module is
// still present and its methods reject with `live_activity_module_unavailable`, so `getEnforcing`
// is accurate here (unlike Location, which really can be absent and uses `get`).
export default TurboModuleRegistry.getEnforcing<Spec>(
  'NativeCustomerIOLiveActivities'
);
