/**
 * This file defines the TypeScript specification for the CustomerIO TurboModule.
 * It follows React Native's New Architecture patterns for TurboModules.
 */

import { TurboModuleRegistry } from 'react-native';
import type { TurboModule } from 'react-native/Libraries/TurboModule/RCTExport';

/**
 * Region configuration for CustomerIO
 */
export enum CioRegion {
  US = 'US',
  EU = 'EU',
}

/**
 * Enum to define how CustomerIO SDK should handle screen view events.
 */
export enum ScreenView {
  All = 'all',
  InApp = 'inApp',
}

/**
 * Log level configuration for CustomerIO SDK
 */
export enum CioLogLevel {
  None = 'none',
  Error = 'error',
  Info = 'info',
  Debug = 'debug',
}

/**
 * Push click behavior configuration for Android
 */
export enum PushClickBehaviorAndroid {
  ResetTaskStack = 'RESET_TASK_STACK',
  ActivityPreventRestart = 'ACTIVITY_PREVENT_RESTART',
  ActivityNoFlags = 'ACTIVITY_NO_FLAGS',
}

/**
 * Configuration for CustomerIO SDK
 */
export interface CioConfig {
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
}

/**
 * Package information for SDK initialization
 */
export interface PackageInfo {
  packageSource: string;
  packageVersion: string;
}

/**
 * CustomerIO TurboModule Specification
 */
export interface Spec extends TurboModule {
  // Initialization
  initialize(config: CioConfig, packageInfo: PackageInfo): void;

  // Identification
  identify(userId: string | null, traits: Record<string, any> | null): void;
  clearIdentify(): void;

  // Tracking
  track(name: string, properties: Record<string, any> | null): void;
  screen(title: string, properties: Record<string, any> | null): void;

  // Attributes
  setProfileAttributes(attributes: Record<string, any>): void;
  setDeviceAttributes(attributes: Record<string, any>): void;

  // Device token management
  registerDeviceToken(token: string): void;
  deleteDeviceToken(): void;
}

export default TurboModuleRegistry.getEnforcing<Spec>('NativeCustomerIO');
