import { TurboModuleRegistry, type TurboModule } from 'react-native';
import type { UnsafeObject } from 'react-native/Libraries/Types/CodegenTypes';

/**
 * Native module specification for CustomerIO Live Activities React Native SDK
 *
 * Live Activities (iOS) / Live Notifications (Android) let you show a live,
 * updating notification driven by a built-in template (Segments, Countdown Timer).
 *
 * @see NativeCustomerIO.ts for detailed documentation on TurboModule patterns,
 * Codegen compatibility, and type safety approach.
 */

type NativeBridgeObject = UnsafeObject;

export interface Spec extends TurboModule {
  /** Start a built-in-template activity. Resolves with the SDK-minted activity id. */
  start(payload: NativeBridgeObject): Promise<string>;
  /** Replace the whole content-state of a running activity. Pass the full desired state. */
  update(activityId: string, payload: NativeBridgeObject): Promise<void>;
  /** End a running activity. */
  end(activityId: string): Promise<void>;
  /**
   * Start a custom (app-defined) activity type. Android renders it via the host app's
   * `createLiveNotification` callback; on iOS custom types require a native `adopt` call,
   * so this rejects on iOS.
   */
  startCustom(
    activityType: string,
    payload: NativeBridgeObject
  ): Promise<string>;
}

// Optional module — NativeModule may be null when Live Activities is not compiled in.
export default TurboModuleRegistry.get<Spec>('NativeCustomerIOLiveActivities');
