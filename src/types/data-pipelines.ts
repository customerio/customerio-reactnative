import type { PushClickBehaviorAndroid } from './push';

/**
 * Key-value pairs for custom user attributes and event properties.
 *
 * Provides a type-safe interface for passing custom data to CustomerIO.
 * While the native bridge uses generic Object types for Codegen compatibility,
 * this type gives developers better TypeScript intellisense and validation.
 *
 * @example
 * ```typescript
 * const attributes: CustomAttributes = {
 *   age: 25,
 *   email: 'user@example.com',
 *   preferences: { theme: 'dark' }
 * };
 * ```
 *
 * @public
 */
export type CustomAttributes = Record<string, any>;

/**
 * Parameters for identifying a user in CustomerIO.
 *
 * @param userId - Unique identifier for the user (email, username, etc.)
 * @param traits - Additional user attributes and properties
 *
 * @public
 */
export interface IdentifyParams {
  userId?: string;
  traits?: CustomAttributes;
}

/**
 * Configuration options for initializing the CustomerIO SDK.
 *
 * @param cdpApiKey - Customer Data Platform API key from CustomerIO dashboard
 * @param migrationSiteId - Legacy site ID for migrating from tracking API
 * @param region - Data center region (US or EU)
 * @param logLevel - SDK logging verbosity level
 * @param apiHost - Override the CDP API host. Use to route SDK traffic through a first-party proxy.
 * @param cdnHost - Override the CDN host. Use to route SDK traffic through a first-party proxy.
 * @param flushAt - Number of events to batch before sending
 * @param flushInterval - Time interval (seconds) to flush events
 * @param screenViewUse - How to handle screen view tracking
 * @param trackApplicationLifecycleEvents - Auto-track app lifecycle events
 * @param autoTrackDeviceAttributes - Auto-track device information
 * @param inApp - In-app messaging configuration
 * @param push - Push notification configuration
 *
 * @public
 */
export type CioConfig = {
  cdpApiKey: string;
  migrationSiteId?: string;
  region?: CioRegion;
  logLevel?: CioLogLevel;
  apiHost?: string;
  cdnHost?: string;
  flushAt?: number;
  flushInterval?: number;
  screenViewUse?: ScreenView;
  trackApplicationLifecycleEvents?: boolean;
  autoTrackDeviceAttributes?: boolean;
  inApp?: {
    siteId: string;
  };
  push?: {
    android?: {
      pushClickBehavior?: PushClickBehaviorAndroid;
    };
  };
  location?: {
    /** Location tracking mode. Defaults to 'manual' if location config is provided. */
    trackingMode?: CioLocationTrackingMode;
  };
};

/**
 * Log levels for CustomerIO SDK debugging and monitoring.
 *
 * Controls the verbosity of SDK logging output for debugging purposes.
 *
 * @public
 */
export enum CioLogLevel {
  /** No logging output */
  None = 'none',
  /** Only error messages */
  Error = 'error',
  /** Error and informational messages */
  Info = 'info',
  /** All messages including debug information */
  Debug = 'debug',
}

/**
 * Data center regions for CustomerIO API endpoints.
 *
 * @public
 */
export enum CioRegion {
  US = 'US',
  EU = 'EU',
}

/**
 * Screen view tracking behavior configuration.
 *
 * Defines how the SDK should handle automatic screen view events
 * for analytics and in-app message targeting.
 *
 * @public
 */
export enum ScreenView {
  /** Send screen events to destinations and display in-app messages */
  All = 'all',
  /** Only display in-app messages, don't send to destinations */
  InApp = 'inApp',
}

/**
 * Location tracking mode for the CustomerIO Location module.
 *
 * @public
 */
export enum CioLocationTrackingMode {
  /** Location tracking is disabled. All location operations no-op. */
  Off = 'OFF',
  /** Host app controls when location is captured (default when location config is provided). */
  Manual = 'MANUAL',
  /** SDK auto-captures location once per app launch when the app becomes active. */
  OnAppStart = 'ON_APP_START',
}

/**
 * Enum to specify the type of metric for tracking
 *
 * @public
 */
export enum MetricEvent {
  /** Push notification was delivered to the device */
  Delivered = 'delivered',
  /** Push notification was opened by the user */
  Opened = 'opened',
  /** Push notification resulted in a conversion */
  Converted = 'converted',
}
