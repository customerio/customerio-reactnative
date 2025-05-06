/**
 * This file defines the TypeScript specification for the CustomerIO Push Messaging module.
 * It follows React Native's New Architecture patterns for TurboModules.
 */

import type { CioPushPermissionOptions } from './CustomerIOTypes';

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

export type { PushMessagingModuleSpec };
