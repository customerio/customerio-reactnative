import { TurboModuleRegistry, type TurboModule } from 'react-native';
/* eslint-disable @react-native/no-deep-imports */
import type { UnsafeObject } from 'react-native/Libraries/Types/CodegenTypes';

/**
 * Native module specification for CustomerIO Push Messaging React Native SDK
 *
 * @see NativeCustomerIO.ts for detailed documentation on TurboModule patterns,
 * Codegen compatibility, and type safety approach.
 */

type NativeBridgeObject = UnsafeObject;

export interface Spec extends TurboModule {
  onMessageReceived(
    message: NativeBridgeObject,
    handleNotificationTrigger: boolean
  ): Promise<boolean>;
  trackNotificationResponseReceived(payload: NativeBridgeObject): void;
  trackNotificationReceived(payload: NativeBridgeObject): void;
  getRegisteredDeviceToken(): Promise<string>;
  showPromptForPushNotifications(options: NativeBridgeObject): Promise<string>;
  getPushPermissionStatus(): Promise<string>;
}

export default TurboModuleRegistry.getEnforcing<Spec>(
  'NativeCustomerIOMessagingPush'
);
