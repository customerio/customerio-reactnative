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
  /**
   * Your own activity type, rendered by SwiftUI you write.
   *
   * Unlike the members above, this value is a marker rather than an identifier — your activity is
   * named by {@link LiveActivitiesConfig.customType}, and the SDK reports it under that name. It
   * belongs in a payload's `type`, never in {@link LiveActivitiesConfig.types}.
   */
  Custom = 'custom',
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
 * Custom template — your own activity type, rendered by SwiftUI you write.
 *
 * Unlike the built-in templates there is no schema: `data` is an untyped map, because a bridge
 * payload carries nothing for the SDK to validate against. Every value is a string, so your widget
 * parses whichever ones it needs.
 *
 * Requires {@link LiveActivitiesConfig.customType} to be set. On iOS you must also render
 * `CIOCustomAttributes` in your Widget Extension; on Android your `createLiveNotification`
 * callback receives the same map.
 *
 * @public
 */
export interface LiveActivityCustomPayload {
  type: LiveActivityTemplate.Custom;
  /**
   * The full content-state, re-sent in its entirety on every update. Neither platform keeps a
   * static/dynamic split for custom types, so include anything your widget needs each time.
   *
   * Values must be strings. Numbers and booleans are coerced, but nested objects and arrays are
   * not supported and the platforms disagree on them — iOS drops them, Android stringifies them —
   * so flatten anything structured before sending it.
   */
  data: Record<string, string>;
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
  | LiveActivitySegmentsPayload
  | LiveActivityCountdownTimerPayload
  | LiveActivityCustomPayload;

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
   *
   * `Custom` is excluded on purpose — it is enabled by {@link LiveActivitiesConfig.customType},
   * and both platforms would silently drop it from this list.
   */
  types?: Exclude<LiveActivityTemplate, LiveActivityTemplate.Custom>[];
  /**
   * Your own reverse-DNS identifier for the custom activity type, e.g.
   * `'com.myapp.rideshare'`. Setting it enables the custom template on both platforms.
   *
   * Start one with `{ type: LiveActivityTemplate.Custom, data: { … } }`; the SDK reports it
   * under this identifier, and your campaigns target it by the same name.
   *
   * Singular by design: iOS resolves an activity's type from its Swift attributes type, and
   * every custom activity shares one. A second identifier could not be told apart, so one
   * identifier is the limit rather than a silent mis-attribution.
   *
   * You must also render it yourself — `CIOCustomAttributes` in an iOS Widget Extension, and
   * the `createLiveNotification` callback on Android.
   */
  customType?: string;
  /** Android Live Notification branding (ignored on iOS). */
  branding?: LiveActivitiesBranding;
}
