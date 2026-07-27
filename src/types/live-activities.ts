/**
 * Public types for the Live Activities module.
 *
 * Live Activities (iOS) / Live Notifications (Android) render live, updating
 * notifications from built-in templates. Two templates ship today: Segments and
 * Countdown Timer. Field names and identifiers are identical across platforms.
 */

/**
 * Built-in activity type identifiers usable from the wrapper.
 *
 * The values are the reverse-DNS identifiers Customer.io uses everywhere — the
 * `notificationType` on the wire, Android's `LiveNotificationType`, and iOS's
 * `CIOSegmentsAttributes.identifier` — so JS, both native SDKs, and the backend
 * share one vocabulary.
 *
 * Use these enum members (not raw strings) for `LiveActivitiesConfig.types` and a
 * payload's `type` to avoid typos.
 *
 * @public
 */
export enum LiveActivityTemplate {
  Segments = 'io.customer.livenotifications.segments',
  CountdownTimer = 'io.customer.livenotifications.countdowntimer',
}

/**
 * Segments template — a progress activity split into N segments.
 * `header` is a static attribute (fixed at start); the rest are content-state.
 *
 * @public
 */
export interface LiveActivitySegmentsPayload {
  type: LiveActivityTemplate.Segments;
  /** Static header line (set at start, never changes). */
  header: string;
  /** Primary status line. */
  status: string;
  /** Optional secondary status line. */
  substatus?: string;
  /** Total number of segments. */
  segmentsTotal: number;
  /** Number of completed segments (clamped to 0..segmentsTotal). */
  segmentsComplete: number;
  /** Optional trailing text (e.g. an ETA). */
  trailingText?: string;
}

/**
 * Countdown Timer template — a live countdown to a target time.
 * `header` is a static attribute (fixed at start); the rest are content-state.
 *
 * @public
 */
export interface LiveActivityCountdownTimerPayload {
  type: LiveActivityTemplate.CountdownTimer;
  /** Static header line (set at start, never changes). */
  header: string;
  /** Primary title line. */
  title: string;
  /** Optional status message. */
  statusMessage?: string;
  /** Target time as epoch **seconds**. Omit to render the finished state. */
  endTime?: number;
}

/**
 * Payload for {@link CustomerIOLiveActivities.start} and
 * {@link CustomerIOLiveActivities.update}.
 *
 * Because ActivityKit replaces content-state wholesale on update, `update` takes the
 * same full payload as `start` — pass the complete desired state each time.
 *
 * @public
 */
export type LiveActivityPayload =
  LiveActivitySegmentsPayload | LiveActivityCountdownTimerPayload;

/**
 * Live Activities branding (Android only). On iOS, branding is compiled into the
 * widget extension's SwiftUI, so these values are ignored there.
 *
 * @public
 */
export interface LiveActivitiesBranding {
  /** Reserved for future use. */
  companyName?: string;
  /** Accent color as "#RRGGBB". */
  accentColorHex?: string;
  /**
   * Bundled Android drawable resource name for the logo, resolved natively.
   * Preferred over {@link LiveActivitiesBranding.logoUrl} when both are set — it
   * needs no network.
   */
  logoResource?: string;
  /** Remote logo URL (downloaded and cached natively). */
  logoUrl?: string;
  /** Android drawable resource name, resolved natively. */
  smallIconResource?: string;
}

/**
 * Live Activities configuration, passed under the `liveNotifications` key of the SDK config.
 *
 * @public
 */
export interface LiveActivitiesConfig {
  /**
   * Built-in activity types to enable. Enables the matching native type on each
   * platform and registers push-to-start for it. Unrecognized identifiers are
   * ignored, so a newer native template can't break an older wrapper build.
   */
  types?: LiveActivityTemplate[];
  /**
   * Reverse-DNS identifiers for custom (app-defined) activity types.
   *
   * **Android only in practice.** Android renders these through the app's
   * `createLiveNotification` callback. On iOS a custom type needs a native Widget
   * Extension and an `adopt()` call, so it cannot be started from JavaScript —
   * `startCustom` always rejects there and this list is ignored.
   */
  customTypes?: string[];
  /** Android Live Notification branding (ignored on iOS). */
  branding?: LiveActivitiesBranding;
}
