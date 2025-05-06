/**
 * This file defines the TypeScript specification for the CustomerIO TurboModule.
 * It follows React Native's New Architecture patterns for TurboModules.
 */

// Import the TurboModule type from React Native
import { TurboModuleRegistry } from 'react-native';
import type { TurboModule } from 'react-native/Libraries/TurboModule/RCTExport';

/**
 * Specification for the CustomerIO TurboModule
 */
export interface Spec extends TurboModule {
  // Initialization
  initialize(
    config: {
      cdpApiKey: string;
      migrationSiteId?: string;
      region?: string;
      logLevel?: string;
      flushAt?: number;
      flushInterval?: number;
      screenViewUse?: string;
      trackApplicationLifecycleEvents?: boolean;
      autoTrackDeviceAttributes?: boolean;
      inApp?: {
        siteId: string;
      };
      push?: {
        android?: {
          pushClickBehavior?: string;
        };
      };
    },
    packageInfo: {
      packageSource: string;
      packageVersion: string;
    }
  ): void;

  // Identification
  identify(userId: string | null, traits: Object | null): void;
  clearIdentify(): void;

  // Tracking
  track(name: string, properties: Object | null): void;
  screen(title: string, properties: Object | null): void;

  // Attributes
  setProfileAttributes(attributes: Object): void;
  setDeviceAttributes(attributes: Object): void;

  // Device token management
  registerDeviceToken(token: string): void;
  deleteDeviceToken(): void;

  // Push messaging
  getPushPermissionStatus(): Promise<string>;
  showPromptForPushNotifications(options: {
    ios?: {
      badge: boolean;
      sound: boolean;
    };
  }): Promise<string>;
  getRegisteredDeviceToken(): Promise<string>;

  // In-app messaging
  dismissMessage(): void;
}

export default TurboModuleRegistry.getEnforcing<Spec>('NativeCustomerIO');
