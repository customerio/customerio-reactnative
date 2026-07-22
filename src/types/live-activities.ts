/**
 * Public types for the Live Activities module.
 *
 * Live Activities (iOS) / Live Notifications (Android) render live, updating
 * notifications from built-in templates. Two templates ship today: Segments and
 * Countdown Timer. Field names and identifiers are identical across platforms.
 *
 * @public
 */

/** Built-in template identifiers usable from the wrapper. */
export type LiveActivityTemplate = 'segments' | 'countdownTimer';

/**
 * Segments template — a progress activity split into N segments.
 * `header` is a static attribute (fixed at start); the rest are content-state.
 */
export interface LiveActivitySegmentsPayload {
  type: 'segments';
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
 */
export interface LiveActivityCountdownTimerPayload {
  type: 'countdownTimer';
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
  | LiveActivitySegmentsPayload
  | LiveActivityCountdownTimerPayload;

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
  /** Remote logo URL (downloaded and cached natively). */
  logoUrl?: string;
  /** Android drawable resource name, resolved natively. */
  smallIconResource?: string;
}

/**
 * Live Activities configuration, passed under the `liveActivities` key of the SDK config.
 *
 * @public
 */
export interface LiveActivitiesConfig {
  /** Built-in templates to enable. Enables the matching native type on each platform. */
  templates?: LiveActivityTemplate[];
  /** Reverse-DNS identifiers for custom (app-defined) activity types. */
  customTypes?: string[];
  /** Android Live Notification branding (ignored on iOS). */
  branding?: LiveActivitiesBranding;
}
