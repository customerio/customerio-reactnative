import { type TurboModule } from 'react-native';
import {
  default as NativeModule,
  type Spec as CodegenSpec,
} from './specs/modules/NativeCustomerIOLiveActivities';
import type { LiveActivityPayload } from './types/live-activities';

/**
 * Ensures all methods defined in codegen spec are implemented by the public module
 *
 * @internal
 */
interface NativeLiveActivitiesSpec extends Omit<
  CodegenSpec,
  keyof TurboModule
> {}

// Live Activities is an optional module — NativeModule may be null when it is not
// compiled in. Promise-returning methods reject with a clear error in that case.
let hasWarnedNotEnabled = false;
const withNativeModule = <T>(
  fn: (native: CodegenSpec) => Promise<T>
): Promise<T> => {
  if (NativeModule) {
    return fn(NativeModule);
  }
  if (__DEV__ && !hasWarnedNotEnabled) {
    hasWarnedNotEnabled = true;
    console.warn(
      'Customer.io: Live Activities module is not available. ' +
        'On iOS, add the CustomerIO Live Activities pods and a Widget Extension; ' +
        'on Android it ships with messaging-push-fcm.'
    );
  }
  return Promise.reject(
    new Error('Customer.io: Live Activities module is not available.')
  );
};

/**
 * Live Activities (iOS) / Live Notifications (Android).
 *
 * Start, update, and end live, updating notifications from built-in templates
 * (Segments, Countdown Timer). Enable the activity types via the `liveNotifications`
 * key of the SDK config passed to {@link CustomerIO.initialize}.
 *
 * @public
 */
export class CustomerIOLiveActivities implements NativeLiveActivitiesSpec {
  /**
   * Start a built-in-template activity.
   *
   * @param payload - Template payload; `payload.type` selects the template.
   * @returns The SDK-minted activity id, used for later `update`/`end`.
   */
  start(payload: LiveActivityPayload): Promise<string> {
    return withNativeModule((native) => native.start(payload));
  }

  /**
   * Replace the whole content-state of a running activity.
   *
   * ActivityKit (iOS) replaces content-state wholesale, so pass the **full** desired
   * state — not just the changed fields. Static attributes (e.g. `header`) cannot
   * change after start and are ignored on iOS.
   *
   * @param activityId - Id returned by {@link CustomerIOLiveActivities.start}.
   * @param payload - The complete desired state.
   */
  update(activityId: string, payload: LiveActivityPayload): Promise<void> {
    return withNativeModule((native) => native.update(activityId, payload));
  }

  /**
   * End a running activity, optionally rendering a final content-state.
   *
   * @param activityId - Id returned by {@link CustomerIOLiveActivities.start}.
   * @param payload - **iOS only.** The final content-state to render as the activity ends.
   *   ActivityKit keeps the last content-state on screen when none is given, so pass one to show
   *   a terminal state (e.g. all segments complete). Android renders its own terminal state and
   *   ignores this.
   */
  end(activityId: string, payload?: LiveActivityPayload): Promise<void> {
    return withNativeModule((native) => native.end(activityId, payload));
  }
}
