/**
 * This file defines the TypeScript specification for the CustomerIO native modules.
 * It follows React Native's New Architecture patterns for TurboModules.
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

/**
 * CustomerIO Core Module Specification
 * 
 * This interface defines the methods that should be implemented by the native module
 * for core CustomerIO functionality.
 */
interface CustomerIOModuleSpec {
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

/**
 * In-App Messaging Module Specification
 * 
 * This interface defines the methods that should be implemented by the native module
 * for in-app messaging functionality.
 */
interface InAppMessagingModuleSpec {
  // Dismiss the currently displayed in-app message
  dismissMessage(): void;
  
  // Event constants
  readonly InAppEventListenerEventName: string;
  
  // Event types
  readonly Events: {
    readonly MessageShown: string;
    readonly MessageDismissed: string;
    readonly MessageActionTaken: string;
    readonly ErrorWithMessage: string;
  };
}

/**
 * Push Messaging Module Specification
 * 
 * This interface defines the methods that should be implemented by the native module
 * for push messaging functionality.
 */
interface PushMessagingModuleSpec {
  // Process a push notification
  handleMessage(message: Record<string, any>, handleNotificationTrigger?: boolean): Promise<boolean>;
  
  // Track push notification metrics
  trackNotificationResponseReceived(payload: Record<string, any>): void;
  trackNotificationReceived(payload: Record<string, any>): void;
  
  // Device token and permissions
  getRegisteredDeviceToken(): Promise<string>;
  showPromptForPushNotifications(options: CioPushPermissionOptions): Promise<string>;
  getPushPermissionStatus(): Promise<string>;
  
  // Constants
  readonly PermissionStatus: {
    readonly Granted: string;
    readonly Denied: string;
    readonly NotDetermined: string;
  };
  
  readonly PushClickBehavior: {
    readonly ResetTaskStack: string;
    readonly ActivityPreventRestart: string;
    readonly ActivityNoFlags: string;
  };
}

// Export all types and interfaces
export type {
  CioConfig,
  CioPushPermissionOptions, CustomerIOModuleSpec, InAppMessageEvent, InAppMessagingModuleSpec, PackageInfo, PushMessagingModuleSpec
};

  export {
    CioLogLevel, CioPushPermissionStatus, CioRegion, InAppMessageEventType, PushClickBehaviorAndroid, ScreenView
  };
