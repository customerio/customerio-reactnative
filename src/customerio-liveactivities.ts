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
   * Report an opened Live Activity and return the URL the app should route.
   *
   * Customer.io tracking URLs are unwrapped to their destination after attribution is recorded.
   * A tracking URL without a destination returns `null`; any other URL is returned unchanged.
   * This method never rejects, so it can safely compose with Expo Router's
   * `redirectSystemPath` hook. On Android it is a pass-through.
   *
   * Use this in exactly one URL-routing layer. Calling it more than once for the same Customer.io
   * tracking URL reports more than one opened event.
   *
   * @param url - The incoming URL from the host's linking lifecycle.
   * @returns The URL to route, or `null` when the Customer.io URL has no destination.
   */
  async handleWidgetUrl(url: string): Promise<string | null> {
    try {
      return await NativeModule.handleWidgetUrl(url);
    } catch {
      return url;
    }
  }

  /**
   * Start a built-in-template activity.
   *
   * @param payload - Template payload; `payload.type` selects the template.
   * @returns The SDK-minted activity id, used for later `update`/`end`.
   */
  start(payload: LiveActivityPayload): Promise<string> {
    return NativeModule.start(payload);
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
    return NativeModule.update(activityId, payload);
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
    return NativeModule.end(activityId, payload);
  }
}
