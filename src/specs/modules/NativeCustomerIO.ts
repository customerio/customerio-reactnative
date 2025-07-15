import { TurboModuleRegistry, type TurboModule } from 'react-native';

/**
 * Types and interfaces are defined here instead of importing from other modules
 * because React Native Codegen does not yet support importing types from external files.
 * By defining them here and exposing them publicly, we avoid type redundancy across the codebase.
 *
 * See https://github.com/facebook/react-native/issues/38769 for more details.
 */

// =============================================================================
// PUBLIC API TYPES - Exposed in the SDK interface
// =============================================================================

/** Data center regions for CustomerIO API endpoints */
export enum CioRegion {
  US = 'US',
  EU = 'EU',
}

/** Log levels for CustomerIO SDK debugging and monitoring */
export enum CioLogLevel {
  None = 'none',
  Error = 'error',
  Info = 'info',
  Debug = 'debug',
}

/**
 * Enum to define how CustomerIO SDK should handle screen view events.
 * - all: Send screen events to destinations for analytics purposes and to display in-app messages
 * - inApp: Only display in-app messages and not send screen events to destinations
 */
export enum ScreenView {
  All = 'all',
  InApp = 'inApp',
}

/** Android-specific behaviors for handling push notification clicks */
export enum PushClickBehaviorAndroid {
  ResetTaskStack = 'RESET_TASK_STACK',
  ActivityPreventRestart = 'ACTIVITY_PREVENT_RESTART',
  ActivityNoFlags = 'ACTIVITY_NO_FLAGS',
}

/** Configuration options for initializing the CustomerIO SDK */
export type CioConfig = {
  cdpApiKey: string;
  migrationSiteId?: string;
  region?: CioRegion;
  logLevel?: CioLogLevel;
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
};

// =============================================================================
// INTERNAL TYPES – Not part of public API
// =============================================================================

/** Arguments passed to native SDK for package identification */
export type NativeSDKArgs = {
  packageSource: string;
  packageVersion: string;
};

/** Parameters for identifying a user with optional ID and traits */
export interface IdentifyParams {
  userId?: string;
  traits?: CustomAttributes;
}

/**
 * Key-value pairs for custom user attributes and event properties.
 * Uses `Object` type for Codegen compatibility, public API redefines as
 * `Record<string, any>` for better typing.
 * Do not export to avoid type conflicts between native bridge and public API.
 */
type CustomAttributes = Object;

// =============================================================================
// TURBO MODULE SPEC – Defines native bridge interface
// =============================================================================

/** TurboModule specification for CustomerIO SDK native methods */
export interface Spec extends TurboModule {
  initialize(config: CioConfig, args: NativeSDKArgs): void;
  identify(params?: IdentifyParams): void;
  clearIdentify(): void;
  track(name: string, properties?: CustomAttributes): void;
  screen(title: string, properties?: CustomAttributes): void;
  setProfileAttributes(attributes: CustomAttributes): void;
  setDeviceAttributes(attributes: CustomAttributes): void;
  registerDeviceToken(token: string): void;
  deleteDeviceToken(): void;
}

export default TurboModuleRegistry.getEnforcing<Spec>('NativeCustomerIO');
