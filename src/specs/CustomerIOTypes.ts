/**
 * This file defines the core types and enums for the CustomerIO SDK.
 */

// Region configuration for CustomerIO
enum CioRegion {
  US = 'US',
  EU = 'EU',
}

// Enum to define how CustomerIO SDK should handle screen view events.
enum ScreenView {
  All = 'all',
  InApp = 'inApp',
}

// Log level configuration for CustomerIO SDK
enum CioLogLevel {
  None = 'none',
  Error = 'error',
  Info = 'info',
  Debug = 'debug',
}

// Push click behavior configuration for Android
enum PushClickBehaviorAndroid {
  ResetTaskStack = 'RESET_TASK_STACK',
  ActivityPreventRestart = 'ACTIVITY_PREVENT_RESTART',
  ActivityNoFlags = 'ACTIVITY_NO_FLAGS',
}

// Push permission status
enum CioPushPermissionStatus {
  Granted = 'GRANTED',
  Denied = 'DENIED',
  NotDetermined = 'NOTDETERMINED',
}

// In-app message event types
enum InAppMessageEventType {
  ErrorWithMessage = 'errorWithMessage',
  MessageActionTaken = 'messageActionTaken',
  MessageDismissed = 'messageDismissed',
  MessageShown = 'messageShown',
}

// Configuration for CustomerIO SDK
interface CioConfig {
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

// Push permission options
interface CioPushPermissionOptions {
  ios?: {
    badge: boolean;
    sound: boolean;
  };
}

// Package information for SDK initialization
interface PackageInfo {
  packageSource: string;
  packageVersion: string;
}

// In-app message event data
interface InAppMessageEvent {
  eventType: InAppMessageEventType;
  messageId: string;
  deliveryId?: string;
  actionValue?: string;
  actionName?: string;
}

// Export all types and interfaces
export type {
  CioConfig,
  CioPushPermissionOptions, InAppMessageEvent, PackageInfo
};

  export {
    CioLogLevel, CioPushPermissionStatus, CioRegion, InAppMessageEventType, PushClickBehaviorAndroid, ScreenView
  };
